import Path from "node:path"
import esbuild from "esbuild"
import Module from "./module"

include = ( dependency ) ->
  dependency.external != true &&
    !( dependency.path.startsWith "(disabled):" )

analyze = ( entries, options = {}) ->

  { cwd, platform, conditions, external } = options
  cwd ?= process.cwd()
  platform ?= "browser"
  conditions ?= [ platform ]
  external = [ "esbuild", ( external ? [])... ]

  do ({ metafile, path, imports, dependency } = {}) ->

    results = for entry in entries

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
          if include dependency
            yield
              source:
                path: Path.normalize dependency.path
              module: await Module.read dependency.path, cwd
              import:
                scope:
                  source: path: Path.normalize path
                  module: await Module.read path, cwd
                specifier: dependency.original

    results[0].concat results[1..]...

export default analyze
export { analyze }
