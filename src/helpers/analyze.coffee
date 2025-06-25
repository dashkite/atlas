
import Path from "node:path"
import esbuild from "esbuild"
import Module from "./module"

include = ( dependency ) ->
  dependency.external != true && 
    !( dependency.path.startsWith "(disabled):" )

analyze = ( entries ) ->

  do ({ metafile, path, imports, dependency } = {}) ->

    results = for entry in entries

      { metafile } = await esbuild.build
          entryPoints: [ entry ]
          bundle: true
          sourcemap: false
          platform: "browser"
          conditions: [ "browser" ]
          outfile: "/dev/null"
          external: [ "esbuild" ]
          metafile: true
          format: "esm"
          treeShaking: false

      for path, { imports } of metafile.inputs 
        for dependency in imports
          if include dependency
            yield
              source:
                path: Path.normalize dependency.path
              module: await Module.read dependency.path
              import:
                scope:
                  source: path: Path.normalize path
                  module: await Module.read path
                specifier: dependency.original
    
    results[0].concat results[1..]...

export default analyze
export { analyze }