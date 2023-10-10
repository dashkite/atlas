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
  current = scope
  loop 
    previous = current
    current = XRL.pop current
    # console.log { current }
    scope = if current == previous
      map.imports
    else
      map.scopes[ current ]
    conflicted = hasScopeConflict { scope, specifier, target }
    return ( map.scopes[ previous ] ?= {} ) if conflicted
    return map.imports if current == previous
      
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