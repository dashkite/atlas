import semver from "semver"
import * as _ from "@dashkite/joy"
import { Resource } from "../resource"
import { error } from "../errors"

class Reference

  @equal: (a, b) ->
    (_.isKind Reference a) && (_.isKind Reference b) &&
      (a.resource == b.resource)

  @similar: _.generic
    name: "Reference.similar",
    description: "Returns true if two references are similar."
    default: -> false

  @conflict: _.generic
    name: "Reference.conflict",
    description: "Returns true if two references are in conflict."
    default: -> true

  @choose: _.generic
    name: "Reference.choose",
    description: "Returns the best of two similar references."
    default: (a, b) -> throw error "reference conflict", a, b

  _.mixin @::, [
    _.getters
      version: -> @manifest.version
      resource: -> @_resource ?= Resource.create @
      scope: -> @resource.scope
      scopes: -> @resource.scopes
  ]

  toString: -> @resource.specifier

export { Reference }
