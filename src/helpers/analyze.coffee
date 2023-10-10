# TODO move this into its own module?
#      with or without the module decoration?

import Path from "node:path"
import esbuild from "esbuild"
import Module from "./module"

include = ( _import ) ->
  _import.external != true && 
    !( _import.path.startsWith "(disabled):" )

analyze = ( entries ) ->

  { metafile } = await esbuild.build
      entryPoints: entries
      bundle: true
      sourcemap: false
      platform: "browser"
      conditions: [ "browser" ]
      outfile: "/dev/null"
      external: [ "esbuild" ]
      metafile: true

  for path, dependency of metafile.inputs 
    path = Path.normalize path
    if dependency.imports.length > 0
      scope = { 
        source: { path }
        module: await Module.read path
      }

      for _import in dependency.imports
        if include _import
          yield {
            source:
              path: Path.normalize _import.path
            module: await Module.read _import.path
            import: { 
              scope
              specifier: _import.original
            }
          }

export default analyze
export { analyze }