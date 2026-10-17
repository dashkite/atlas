import Path from "node:path"
import esbuild from "esbuild"
import ModuleCache from "./module"

resolveOptions = ( options ) ->
  cwd = options.cwd ? process.cwd()
  platform = options.platform ? "node"
  {
    cwd: cwd
    source: Path.resolve cwd, ( options.source ? "." )
    platform: platform
    conditions: options.conditions ? [ platform ]
    external: [ "esbuild", ( options.external ? [] )... ]
  }

buildOptions = ( entry, options ) ->
  {
    entryPoints: [ Path.resolve options.source, entry ]
    bundle: true, sourcemap: false, treeShaking: false
    platform: options.platform, conditions: options.conditions
    outfile: "/dev/null", external: options.external
    metafile: true, format: "esm"
    absWorkingDir: Path.resolve options.cwd
  }

buildMetafile = ( entry, options ) ->
  { metafile } = await esbuild.build buildOptions entry, options
  metafile

# Skip external dependencies explicitly marked by esbuild, or disabled ones
isIncluded = ( dependency ) ->
  ( dependency.external != true ) &&
    ( !( dependency.path.startsWith "(disabled):" ) )

createDependency = ( dependency, path, modules ) ->
  source: path: Path.normalize dependency.path
  module: await modules.read dependency.path
  import:
    scope:
      source: path: Path.normalize path
      module: await modules.read path
    specifier: dependency.original

generateDependencies = ( entries, options ) ->
  modules = ModuleCache.make options.cwd
  for entry in entries
    metafile = await buildMetafile entry, options
    for path, { imports } of metafile.inputs
      for dependency in imports
        if isIncluded dependency
          yield await createDependency dependency, path, modules
  return

# Returns an async generator yielding dependency objects
analyze = ( entries, options = {} ) ->
  generateDependencies entries, resolveOptions options

export default analyze
export { analyze }
