import Directory from "#helpers/directory"
import XRL from "#helpers/xrl"
import { Source, Specifier } from "#helpers/dependency"
import Generators from "#generators"

getURL = ({ source, module }) ->
  do ({ path } = {}) ->
    path = Source.relative { source, module }
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

getSpecifier = ( dependency ) ->
  if Specifier.isRelative dependency
    XRL.join [
      XRL.pop getURL dependency.import.scope
      dependency.import.specifier
    ]      
  else 
    dependency.import.specifier
  
CDNs =

  jsdelivr:

    matches: ( dependency ) ->
      Directory.contains "node_modules",
        dependency.source.path

    apply: ( dependency ) ->
      scope: await Generators.scope dependency.import.scope
      specifier: getSpecifier dependency
      target: getURL dependency
    
    scope: getURL

CDN =

  make: ( name ) -> CDNs[ name ]

export { CDN }
export default CDN