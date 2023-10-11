# TODO move this into its own module?
#      with or without the module decoration?

import Path from "node:path"
import esbuild from "esbuild"
import Module from "./module"

include = ( dependency ) ->
  dependency.external != true && 
    !( dependency.path.startsWith "(disabled):" )

analyze = ( entries ) ->

  do ({ metafile, path, imports, dependency } = {}) ->

    { metafile } = await esbuild.build
        entryPoints: entries
        bundle: true
        sourcemap: false
        platform: "browser"
        conditions: [ "browser" ]
        outfile: "/dev/null"
        external: [ "esbuild" ]
        metafile: true

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

export default analyze
export { analyze }