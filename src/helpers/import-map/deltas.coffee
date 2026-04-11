import XRL from "../xrl"

deltas = ({ scope, specifier, target }) ->
  
  # 1. Removal (null scope)
  yield ( map ) ->
    delete map.scopes[ scope ]?[ specifier ]
    map

  # 2. Root (/)
  yield ( map ) ->
    delete map.scopes[ scope ]?[ specifier ]
    map.imports[ specifier ] = target
    map

  # 3. Ancestors (Broadest to Narrowest)
  ancestors = []
  current = scope
  loop
    parent = XRL.directory XRL.pop current
    break if parent == current or parent == "/"
    ancestors.push parent
    current = parent
  
  for ancestor in ancestors.reverse()
    yield ( map ) ->
      delete map.scopes[ scope ]?[ specifier ]
      map.scopes[ ancestor ] ?= {}
      map.scopes[ ancestor ][ specifier ] = target
      map

export default deltas
