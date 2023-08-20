import Path from "node:path"
import FS from "node:fs/promises"
import esbuild from "esbuild"
import * as Fn from "@dashkite/joy/function"
import { generic } from "@dashkite/joy/generic"
import * as Pred from "@dashkite/joy/predicate"
import * as Type from "@dashkite/joy/type"
import { expand as _expand } from "@dashkite/polaris"
import * as YAML from "js-yaml"

# TODO this should probably already be curried?
expand = Fn.curry ( template, context ) -> 
  _expand template, context

split = ( path ) -> path.split Path.sep
join = ( components ) -> components.join Path.sep

cache = {}
read = ( path ) ->
  cache[ path ] ?= await FS.readFile path, "utf8"

exists = ( path ) ->
  try
    await read path
    true
  catch
    false

withinFolder = Fn.curry ( folder, path ) ->
  (( split path ).find ( component ) -> component == folder )?

withinNodeModules = withinFolder "node_modules"

withinPath = Fn.curry ( target, path ) ->
  !(( Path.relative target, path ).startsWith "." )

withinEntryPoints = ( targets, path ) ->
  (
    targets
      .map ( target ) -> Path.dirname target
      .find ( target ) -> 
        withinPath target, path
  )?

isLocal = ({ entries, source }) -> 
  withinEntryPoints entries, source.path

isDevelopment = ({ entries, source }) -> 
  !withinEntryPoints entries, source.path

isScopedDevelopment = ( context ) -> 
  context.scope? && isDevelopment context

isProduction = ({ source }) -> 
  withinNodeModules source.path

isScopedProduction = ( context ) -> 
  context.scope? && isProduction context

readModuleInfo = ( path ) ->
  { name, version } = JSON.parse await read Path.join path, "package.json"
  if name.startsWith "@"
    [ scope, name ] = name[1..].split "/"
    { scope, name, version }
  else { name, version }

getModulePath = ( path ) ->
  directory = Path.dirname path
  until directory == "."
    if await exists Path.join directory, "package.json"
      return directory
    directory = Path.dirname directory
  throw new Error "No module path found for #{ path }"

# TODO implement
# TODO this should arguably take the source.path also
#      so we can use a file hash if we prefer

readBuildInfo = ( path ) ->
  try
    YAML.load await read Path.join path, ".genie/build.yaml"
  catch
    {}

getHash = ( path ) ->
  { hash } = await readBuildInfo path
  hash

getModuleInfo = ( path ) ->
  modulePath = await getModulePath path
  relativePath = Path.relative modulePath, path
  { scope, name, version } = await readModuleInfo modulePath
  hash = await getHash modulePath
  { scope, name, version, hash, path: relativePath }

getURL = generic
  name: "getURL"
  description: "Obtain a URL from a path or module description"

generic getURL, isLocal, ({ path }) ->
  expand "/${ path }",
    path: Path.relative "build/browser/src", path

generic getURL, isProduction, 
	expand "https://cdn.jsdelivr.net/npm/\
    ${ name }@${ version}/${ path }"

generic getURL, isScopedProduction, 
	expand "https://cdn.jsdelivr.net/npm/\
    @${ scope }/${ name }@${ version}/${ path }"

generic getURL, isDevelopment, 
	expand "https://modules.dashkite.io/\
    ${ hash }/${ name }@${ version}/${ path }"

generic getURL, isScopedDevelopment, 
	expand "https://modules.dashkite.io/\
    ${ hash }/@${ scope }/${ name }@${ version}/${ path }"

includeMapping = ( mapping ) ->
  mapping.external != true && 
    !( mapping.path.startsWith "(disabled):" )

getContext = ({ path, entries }) ->
  info = await getModuleInfo path
  url = await getURL { info..., entries, source: { path }}
  { info..., source: { path }, url }

generate = ( entries ) ->
  { metafile } = await esbuild.build
      entryPoints: entries
      bundle: true
      sourcemap: false
      platform: "browser"
      conditions: [ "browser" ]
      outfile: "/dev/null"
      external: [ "esbuild" ]
      metafile: true

  result = []

  for scope, mappings of metafile.inputs when mappings.imports.length > 0
    _scope = await getContext
      entries: entries
      path: scope

    for mapping in mappings.imports when includeMapping mapping
      _context = await getContext
        entries: entries
        path: mapping.path
      result.push { 
        _context...
        import:
          scope: _scope.url
          specifier: mapping.original
      }

  result

  specifiers = {}

  for mapping in result
    specifier = ( specifiers[ mapping.import.specifier ] ?= {})
    mappings = ( specifier[ mapping.url ] ?= [])
    mappings.push mapping

  specifiers

export { generate }
