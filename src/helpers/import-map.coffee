import * as Fn from "@dashkite/joy/function"
import * as Val from "@dashkite/joy/value"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import XRL from "#helpers/xrl"
import Generators from "#generators"

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
    # 1. Capture Ground Truth & Frequency Tally
    original = {}
    counts = {} # counts[specifier][target] = frequency

    tally = ( specifier, target ) ->
      counts[ specifier ] ?= {}
      counts[ specifier ][ target ] ?= 0
      counts[ specifier ][ target ] += 1

    for specifier, target of map.imports
      tally specifier, target
    
    for scope, mappings of map.scopes
      original[scope] = Object.assign {}, mappings
      for specifier, target of mappings
        tally specifier, target

    # 2. Global Promotion (Hoisting)
    map.imports = {}
    for specifier, targets of counts
      bestTarget = null
      maxCount = 0
      for target, num of targets
        if num > maxCount
          maxCount = num
          bestTarget = target
      map.imports[ specifier ] = bestTarget

    # 3. Intermediate Lifting Pass
    # Find all original mappings that differ from global default
    groups = {}
    for scope, mappings of original
      for specifier, target of mappings
        if map.imports[specifier] != target
          groups[specifier] ?= {}
          groups[specifier][target] ?= []
          groups[specifier][target].push scope

    candidates = {} # candidates[scope][specifier][target] = count
    
    for specifier, targets of groups
      for target, scopes of targets
        for originalScope in scopes
          current = originalScope
          loop
            parent = XRL.directory XRL.pop current
            
            # Check for conflict: 
            # Does any other scope under parent resolve this specifier differently?
            conflict = false
            for s, m of original
              if s.startsWith(parent) and m[specifier]? and m[specifier] != target
                conflict = true
                break
            
            if conflict or parent == current or parent == "/"
              # Stop at current
              candidates[current] ?= {}
              candidates[current][specifier] ?= {}
              candidates[current][specifier][target] ?= 0
              candidates[current][specifier][target] += 1
              break
            
            current = parent

    # 4. Reconstruction & In-Place Redundancy Removal
    # helper to find what the browser resolves at a given scope
    resolve = ( specifier, scope ) ->
      current = scope
      loop
        if map.scopes[current]?[specifier]?
          return map.scopes[current][specifier]
        parent = XRL.directory XRL.pop current
        if parent == current or parent == "/"
          return map.imports[specifier]
        current = parent

    map.scopes = {}
    # Process from broadest to deepest
    sortedScopes = (Object.keys candidates).sort (a, b) -> a.length - b.length
    for scope in sortedScopes
      for specifier, targets of candidates[scope]
        for target, count of targets
          # Only add if it differs from inherited resolution
          if resolve(specifier, scope) != target
            (map.scopes[scope] ?= {})[specifier] = target

    map

export default Map
export { Map }
