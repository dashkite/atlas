import * as _ from "@dashkite/joy"
import { Reference } from "./reference"
import { ModuleScope } from "./scope"

class Resource

  @specifier: (name, version) -> "#{name}@#{version}"

  @create: do (cache = {}) ->
    (reference) ->
      {name} = reference
      manifest = await reference.manifest
      version = manifest.version
      dependencies = await reference.dependencies
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
          r.add await @scope
          await Promise.all (
            for d from @dependencies
              do -> r.add await d.scope
          )
          r

  ]

export { Resource }
