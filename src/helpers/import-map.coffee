import * as Fn from "@dashkite/joy/function"
import * as Val from "@dashkite/joy/value"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import XRL from "#helpers/xrl"
import Generators from "#generators"

import lca from "./lca"
import groupByMapping from "./group-by-mapping"
import buildScopes from "./build-scopes"
import buildRoot from "./build-root"

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
    groups = groupByMapping { map.scopes..., "/": map.imports }
    pairs = groups.map ({ mapping, scopes }) -> 
      { mapping, scopes: lca [ scopes... ] }
    
    intermediate = buildScopes pairs
    { imports, scopes } = buildRoot intermediate
    
    map.imports = imports
    map.scopes = scopes
    
    map

export default Map
export { Map }
