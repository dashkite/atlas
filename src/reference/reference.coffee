import * as _ from "@dashkite/joy"
import { Resource } from "../resource"
import { error } from "../errors"

class Reference
  _.mixin @::, [
    _.getters
      resource: -> @_resource ?= Resource.create @
      scope: -> (await @resource).scope
      scopes: -> (await @resource).scopes
      dependencies: ->
        @_dependencies ?= do =>
          r = new Set
          manifest = await @manifest
          await Promise.all (
            for name, description of manifest.dependencies
              do -> r.add await Reference.create name, description
          )
          r
  ]

export { Reference }
