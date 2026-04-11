import * as Fn from "@dashkite/joy/function"
import * as Val from "@dashkite/joy/value"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import XRL from "#helpers/xrl"
import Generators from "#generators"

hasConflict = ({ mapping, specifier }) ->
  mapping?[ specifier ]?

popScope = ( scope ) ->
  if candidate == current then "/" else candidate

findMinimalScope = ({ map, scope, specifier, target }) ->
  current = last = scope
  loop
    current = XRL.pop current
    if current == last
      if map.imports[ specifier ]?
        if map.imports[ specifier ] == target
          return undefined
        else
          return last
      else
        return "/"
    else
      if map.scopes[ current ]?[ specifier ]?
        if map.imports[ specifier ] == target
          return undefined
        else
          return last
      else
        last = current
    
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
            if scope.startsWith "/"
              map.imports
            else
              map.scopes[ XRL.directory scope ] ?= {}
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
    remove = []
    for scope, mappings of map.scopes
      for specifier, target of mappings
        minimal = findMinimalScope { map, scope, specifier, target }
        if !minimal?
          # minimal scope already has this mapping
          continue
        else if minimal != scope
          # minimal scope exists that isn't the full scope
          remove.push { scope, specifier }
          if minimal == "/"
            map.imports[ specifier ] = target
          else
            map.scopes[ minimal ] ?= {}
            map.scopes[ minimal ][ specifier ] = target

    # remove all the redundant specifiers
    for { scope, specifier } in remove
      delete map.scopes[ scope ][ specifier ]
    
    # remove any (now) empty scopes
    for scope, mappings of map.scopes
      keys = Object.keys mappings
      delete map.scopes[ scope ] if keys.length == 0

    map

export default Map
export { Map }
