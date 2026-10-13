import AtlasURL from "../url"
import Path from "node:path"
import micromatch from "micromatch"
import { pathToFileURL } from "node:url"
import { decode as urlDecode } from "@dashkite/url-codex"

SCOPED_TEMPLATE = "/{scope}/{versioned}/{path*}"
UNSCOPED_TEMPLATE = "/{versioned}/{path*}"
DEFAULT_PATTERNS = [ "../**/*", "packages/**/*" ]

normalizeConfig = ( config = {} ) ->
  if !config.root?
    throw new Error "Local resolver requires 'root' in configuration"
  root: config.root
  cwd: config.cwd ? process.cwd()
  patterns: config.patterns ? DEFAULT_PATTERNS

normalizeRelativePath = ( path, cwd ) ->
  if Path.isAbsolute path
    Path.relative cwd, path
  else
    path

matchPattern = ( path, patterns, cwd ) ->
  if path.includes "node_modules"
    return false
  if patterns.length == 0
    return false
  path = normalizeRelativePath path, cwd
  micromatch.isMatch path, patterns, { contains: true }

decodePathname = ( pathname ) ->
  try
    match = urlDecode SCOPED_TEMPLATE, pathname
    if match.scope?.startsWith "@" then match else throw new Error
  catch
    urlDecode UNSCOPED_TEMPLATE, pathname

parseModule = ( scope, versioned ) ->
  parts = versioned.split "@"
  scope: scope
  name: parts[0]
  version: parts[1]

formatPath = ( path ) ->
  "/" + ( path ? [] ).join "/"

decodeUrl = ( url ) ->
  parsed = AtlasURL.parse url
  result = decodePathname parsed.pathname
  {
    resolver: parsed.resolver
    module: parseModule result.scope, result.versioned
    path: formatPath result.path
  }

resolvePath = ( root, descriptor ) ->
  path = descriptor.path
  path = path.slice 1 if path.startsWith "/"
  path = Path.resolve root, path
  ( pathToFileURL path ).href

make = ( config = {} ) ->
  { root, cwd, patterns } = normalizeConfig config
  match: ( context = {} ) -> matchPattern context.source, patterns, cwd
  encode: ( descriptor ) -> AtlasURL.format descriptor
  decode: ( url ) -> decodeUrl url
  parse: ( url ) -> @decode url
  resolve: ( url ) -> resolvePath root, @decode url

export default { make }
export { make }