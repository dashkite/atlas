import Path from "node:path"
import esbuild from "esbuild"
import Module from "./module"

resolveOptions = ( options = {} ) ->
  platform = options.platform ? "node"
  {
    cwd: options.cwd ? process.cwd()
    platform: platform
    conditions: options.conditions ? [ platform ]
    external: [ "esbuild", ( options.external ? [] )... ]
  }

buildOptions = ( entry, options ) ->
  {
    entryPoints: [ entry ]
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
  dependency.external != true && !(dependency.path.startsWith "(disabled):")

createDependency = ( dependency, path, workingDirectory ) ->
  source: path: Path.normalize dependency.path
  module: await Module.read dependency.path, workingDirectory
  import:
    scope:
      source: path: Path.normalize path
      module: await Module.read path, workingDirectory
    specifier: dependency.original

generateDependencies = ( entries, options ) ->
  for entry in entries
    metafile = await buildMetafile entry, options
    for path, { imports } of metafile.inputs
      for dependency in imports
        if isIncluded dependency
          yield await createDependency dependency, path, options.cwd
  return

# Returns an async generator yielding dependency objects
analyze = ( entries, options = {} ) ->
  generateDependencies entries, resolveOptions options

export default analyze
export { analyze }
