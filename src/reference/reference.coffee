import * as _ from "@dashkite/joy"
import { Resource } from "../resource"
import { error } from "../errors"

class Reference

  @equal: (a, b) ->
    (_.isKind Reference a) && (_.isKind Reference b) &&
      (a.resource == b.resource)

  _.mixin @::, [
    _.getters
      version: -> @manifest.version
      resource: -> @_resource ?= Resource.create @
      scope: -> @resource.scope
      scopes: -> @resource.scopes
  ]

export { Reference }
