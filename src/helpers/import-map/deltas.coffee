import XRL from "../xrl"

isPackageScope = ( scope ) ->
  segments = scope.split(/\/node_modules\/|node_modules\//).filter Boolean
  return false if segments.length == 0
  leaf = segments[ segments.length - 1 ].replace /\/$/, ""
  parts = leaf.split "/"
  if parts[ 0 ].startsWith "@"
    parts.length == 2
  else
    parts.length == 1

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
      segments = parent.split(/\/node_modules\/|node_modules\//).filter Boolean
      if segments.length > 0
        leaf = segments[ segments.length - 1 ].replace /\/$/, ""
        parts = leaf.split "/"
        if ( parts.length == 1 && parts[ 0 ].startsWith "@" )
          break
      if parent == "/node_modules/" || parent.endsWith "/node_modules/"
        break
      ancestors.push parent
      if ( specifier.startsWith "#" ) && isPackageScope parent
        break
      current = parent
    
    for ancestor in ancestors.reverse()
      yield ( map ) ->
        delete map.scopes[ scope ]?[ specifier ]
        map.scopes[ ancestor ] ?= {}
        map.scopes[ ancestor ][ specifier ] = target
        map

export default deltas
