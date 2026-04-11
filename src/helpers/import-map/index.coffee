import * as Fn from "@dashkite/joy/function"
import * as Val from "@dashkite/joy/value"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import XRL from "#helpers/xrl"
import Generators from "#generators"
import groupByMapping from "./group-by-mapping"
import groupBySpecifier from "./group-by-specifier"
import resolve from "./resolve"
import deltas from "./deltas"
import verify from "./verify"
import compact from "./compact"

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

  optimize: ( map ) ->
    mappings = groupByMapping { $: map.imports, map.scopes... }
    specifiers = groupBySpecifier mappings

    for { mapping, scopes } in mappings
      { specifier, target } = mapping
      for scope from scopes when scope != "$"
        for delta from deltas { scope, specifier, target }
          modified = delta structuredClone map
          if verify { map: modified, specifier, target, scopes: specifiers[ specifier ] }
            map = modified
            break
    compact map

  compact: ( map ) -> Map.optimize map

export default Map
export { Map }
