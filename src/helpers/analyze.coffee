import Path from "node:path"
import esbuild from "esbuild"
import Module from "./module"

analyze = ( entries, options = {} ) ->
  { cwd, platform, conditions, external } = options
  cwd ?= process.cwd()
  platform ?= "node"
  conditions ?= [ platform ]
  external = [ "esbuild", ( external ? [])... ]

  # Returns an async generator yielding dependency objects
  do ->
    for entry in entries
      { metafile } = await esbuild.build
        entryPoints: [ entry ]
        bundle: true
        sourcemap: false
        platform: platform
        conditions: conditions
        outfile: "/dev/null"
        external: external
        metafile: true
        format: "esm"
        treeShaking: false
        absWorkingDir: Path.resolve cwd

      for path, { imports } of metafile.inputs
        for dependency in imports
          # Skip external dependencies explicitly marked by esbuild, or disabled ones
          if dependency.external != true && !(dependency.path.startsWith "(disabled):")
            yield
              source:
                path: Path.normalize dependency.path
              module: await Module.read dependency.path, cwd
              import:
                scope:
                  source: path: Path.normalize path
                  module: await Module.read path, cwd
                specifier: dependency.original

export default analyze
export { analyze }
