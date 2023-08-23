import Path from "node:path"

import esbuild from "esbuild"
import { Directory } from "./file"
import { getModuleInfo } from "./module"

includeMapping = ( mapping ) ->
  mapping.external != true && 
    !( mapping.path.startsWith "(disabled):" )

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

  for path, mappings of metafile.inputs when mappings.imports.length > 0
    module = await getModuleInfo path

    for mapping in mappings.imports when includeMapping mapping
      yield {
          source:
            path: mapping.path
          module: ( _module = await getModuleInfo mapping.path )
          path: Path.relative _module.path, mapping.path
          local: ( entries.find ( entry ) ->
              Directory.within _module.path, entry )?            
          import: {
            scope: { module }
            specifier: mapping.original
          }
        }

export { analyze }