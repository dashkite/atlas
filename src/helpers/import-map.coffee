import XRL from "#helpers/xrl"

hasSpecifierConflict = ({ scope, specifier, target }) ->
  if ( _target = scope[ specifier ])?
    _target != target 
  else false

hasScopeConflict = ({ scope, specifier, target }) ->
  if scope?
    hasSpecifierConflict {
      scope
      specifier
      target
    }
  else
    false
    
findMinimalScope = ({ map, scope, specifier, target }) ->
  loop 
    child = scope
    scope = XRL.pop scope
    return map.imports if child == scope
    conflicted = hasScopeConflict { 
      scope: map.scopes[ scope ]
      specifier
      target 
    }
    return map.scopes[ child ] ?= {} if conflicted
      

Map =

  make: -> imports: {}, scopes: {}

  from: ({ imports, scopes }) -> { imports, scopes }

  add: ( map, mapping ) ->
    if mapping?
      do ({ scope, specifier, target } = mapping ) ->
        scope = if scope?
          findMinimalScope { map, scope, specifier, target }
          # map.scopes[ scope ] ?= {}
        else
          map.imports
        ( scope[ specifier ] = target ) unless specifier == target
    map

export default Map
export { Map }