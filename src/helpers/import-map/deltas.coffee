import XRL from "../xrl"

deltas = ({ scope, specifier, target }) ->
  
  # 1. Removal (null scope)
  yield ( map ) ->
    delete map.scopes[ scope ]?[ specifier ]
    map

  # 2. Root (/) - only for bare/external specifiers
  unless ( specifier.startsWith "." ) || ( specifier.startsWith "#" )
    yield ( map ) ->
      delete map.scopes[ scope ]?[ specifier ]
      map.imports[ specifier ] = target
      map

  # 3. Ancestors (Broadest to Narrowest)
  unless specifier.startsWith "."
    ancestors = []
    current = scope
    loop
      parent = XRL.directory XRL.pop current
      break if parent == current or parent == "/"
      if ( specifier.startsWith "#" ) && ( parent.endsWith( "/node_modules/" ) || parent == "/" )
        break
      ancestors.push parent
      current = parent
    
    for ancestor in ancestors.reverse()
      yield ( map ) ->
        delete map.scopes[ scope ]?[ specifier ]
        map.scopes[ ancestor ] ?= {}
        map.scopes[ ancestor ][ specifier ] = target
        map

export default deltas
