import * as Fn from "@dashkite/joy/function"
import * as Val from "@dashkite/joy/value"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import XRL from "#helpers/xrl"
import Generators from "#generators"

hasSpecifierConflict = ({ scope, specifier, target }) ->
  if scope[ specifier ]?
    scope[ specifier ] != target
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
      current = XRL.directory XRL.pop current
      _scope = if current == previous
        if current == "/"
          map.imports
        else
          map.scopes[ current ]
      else
        map.scopes[ current ]
      conflicted = hasScopeConflict { scope: _scope, specifier, target }
      if conflicted
        return ( map.scopes[ previous ] ?= {}) 
      if current == previous
        return do ->
          if current == "/"
            map.imports
          else
            map.scopes[ current ] ?= {}

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
        unless specifier == target
          _scope = if scope?
            # findMinimalScope { map, scope, specifier, target }
            if scope.startsWith "/"
              map.imports
            else
              map.scopes[ XRL.directory XRL.pop scope ] ?= {}
          else
            map.imports
          _scope[ specifier ] = target
        map

    generic add, Type.isObject, Type.isReactor, ( map, it ) ->
      for await dependency from it
        await Map.add map, dependency
      map

    add

  compact: ( map ) ->
    result = map.scopes
    scopes = Object.keys map.scopes
    last = []
    while !( Val.equal scopes, last )
      last = scopes
      previous = result
      result = {}
      for current in scopes
        parent = XRL.directory XRL.pop current
        if !( result[ parent ]? )
          result[ parent ] = previous[ current ]
        else
          conflict = false
          for specifier, target of result[ parent ]
            conflict = hasSpecifierConflict
              scope: previous[ current ]
              specifier: specifier
              target: target
            break if conflict
          if !conflict
            Object.assign result[ parent ], previous[ current ]
          else if result[ current ]?
            Object.assign result[ current ], previous[ current ]
          else
            result[ current ] = previous[ current ]
      scopes = Object.keys result
    map.scopes = result
    map

export default Map
export { Map }