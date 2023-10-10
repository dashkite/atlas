import Path from "node:path"
import Directory from "#helpers/directory"
import XRL from "#helpers/xrl"
import { Specifier } from "#helpers/dependency"
import Generators from "#generators"

getURL = ({ dependency }) ->
  do ({ path } = {}, { source, module } = dependency ) ->
    path = Path.relative module.path, source.path
    do ({ scope, name, version } = module ) ->
      if scope?
        XRL.join [
          "https://cdn.jsdelivr.net/npm"
          "@#{ scope }"
          "#{ name }@#{ version }"
          path
        ]
      else
        XRL.join [
          "https://cdn.jsdelivr.net/npm"
          "#{ name }@#{ version }"
          path
        ]

getSpecifier = ({ dependency }) ->
  if Specifier.isRelative dependency
    XRL.join [
      XRL.pop getURL dependency: dependency.import.scope
      dependency.import.specifier
    ]      
  else 
    dependency.import.specifier
  
CDNs =

  jsdelivr:

    matches: ({ dependency }) ->
      Directory.contains "node_modules",
        dependency.source.path

    apply: ({ dependency }) ->
      scope = await Generators.scope 
        dependency: dependency.import.scope
      specifier = getSpecifier { dependency }
      target = getURL { dependency }
      { scope, specifier, target }
    
    scope: getURL

CDN =

  make: ( name ) -> CDNs[ name ]

export { CDN }
export default CDN