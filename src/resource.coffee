import * as _ from "@dashkite/joy"
import { Reference } from "./reference"
import { ModuleScope } from "./scope"

class Resource

  @specifier: (name, version) -> "#{name}@#{version}"

  @create: do (cache = {}) ->
    (reference) ->
      {name, manifest, dependencies} = reference
      version = manifest.version
      cache[ (Resource.specifier name, version) ] ?=
        _.assign new Resource, {name, manifest, dependencies}

  _.mixin @::, [
    _.getters
      version: -> @manifest.version
      specifier: -> Resource.specifier @name, @version
      scope: -> @_scope ?= ModuleScope.create @
      scopes: ->
        @_scopes ?= do =>
          r = new Set
          r.add @scope
          for d from @dependencies
            for s from d.scopes
              r.add s
          r

  ]

export { Resource }
