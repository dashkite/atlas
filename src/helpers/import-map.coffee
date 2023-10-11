import * as Fn from "@dashkite/joy/function"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import XRL from "#helpers/xrl"
import Generators from "#generators"

hasSpecifierConflict = ({ scope, specifier, target }) ->
  do ({ _target } = {}) ->
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
  do ({ current, previous, confliced } = {}) ->
    current = scope
    loop 
      previous = current
      current = XRL.pop current
      scope = if current == previous
        map.imports
      else
        map.scopes[ current ]
      conflicted = hasScopeConflict { scope, specifier, target }
      return ( map.scopes[ previous ] ?= {} ) if conflicted
      return map.imports if current == previous

isDependency = ( value ) ->
  value?.source? && value.import? && value.module?

isMapping = ( value ) ->
  value?.specifier? && value.target?

Map =

  make: -> imports: {}, scopes: {}

  from: ({ imports, scopes }) -> { imports, scopes }

  add: do ({ add } = {}) ->

    add = generic name: "Map.add"

    generic add, Type.isObject, Type.isUndefined, Fn.identity

    generic add, Type.isObject, isDependency, 
      ( map, dependency ) -> 
        add map, await Generators.apply dependency
    
    generic add, Type.isObject, isMapping,
      ( map, { scope, specifier, target }) ->
        scope = if scope?
          findMinimalScope { map, scope, specifier, target }
          # map.scopes[ scope ] ?= {}
        else
          map.imports
        unless specifier == target
          scope[ specifier ] = target
        map
    
    add
      

export default Map
export { Map }