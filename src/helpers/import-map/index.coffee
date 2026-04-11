import * as Fn from "@dashkite/joy/function"
import * as Val from "@dashkite/joy/value"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import XRL from "#helpers/xrl"
import Generators from "#generators"

import lca from "./lca"
import groupByMapping from "./group-by-mapping"
import buildScopes from "./build-scopes"
import resolve from "./resolve"

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

    groups = groupByMapping {
      $: map.imports
      map.scopes...
    }

    pairs = groups.map ({ mapping, scopes }) -> 
      { mapping, scopes: lca [ scopes... ] }
    
    { $: imports, scopes... } = buildScopes pairs
    
    original = structuredClone map
    map = { scopes, imports }

    # Iterate through each scope and mapping and try
    # removing it to see if it still resolves.
    for scope, mappings of map.scopes
      for specifier, target of mappings
        delete map.scopes[scope][specifier]
        if target == resolve { map, specifier, base: scope }
          # still resolves, mapping was redundant
          continue
        else
          # breaks resolution, put it back
          map.scopes[scope][specifier] = target
    
    # Cleanup empty scopes
    for scope, mappings of map.scopes
      if ( Object.keys mappings ).length == 0
        delete map.scopes[scope]

    before = ( JSON.stringify original ).length
    after =  ( JSON.stringify map ).length
    console.log "optimization saved #{ before - after } bytes"
    map



export default Map
export { Map }
