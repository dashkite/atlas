import Directory from "#helpers/directory"
import XRL from "#helpers/xrl"
import { Source, Specifier } from "#helpers/dependency"
import Generators from "#generators"

getURL = ({ source, module }) ->
  do ({ path } = {}) ->
    path = Source.relative { source, module }
    do ({ specifier, version } = module ) ->
      XRL.join [
        "https://cdn.jsdelivr.net/npm"
        "#{ specifier }@#{ version }"
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
      Source.isPublished dependency

    apply: ( dependency ) ->
      scope: await Generators.scope dependency.import.scope
      specifier: getSpecifier dependency
      target: getURL dependency
    
    scope: getURL

CDN =

  make: ({ provider }) -> CDNs[ provider ]

export { CDN }
export default CDN