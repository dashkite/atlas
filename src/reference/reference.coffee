import semver from "semver"
import * as _ from "@dashkite/joy"
import micromatch from "micromatch"
import { Resource } from "../resource"
import { ImportMap } from "../import-map"
import { error } from "../errors"

entry = (path) ->
  if path.startsWith "."
    path
  else
    "./#{path}"
    
subpaths = (reference, current) ->
  current ?= reference.manifest.exports
  rx = {}
  for key, value of current
    if key.startsWith "."
      if key.endsWith "*"
        if _.isObject value
          if value.export?
            target = value.export
          else
            throw error "no export condition", reference.name, reference.version
        else
          target = value
        pattern = target.replace "*", "**"
        for path in reference.capture pattern
          rx[ (key.replace "*", path) ] = target.replace "*", path
      else
        if _.isObject value
          if value.export?
            rx[key] = value.export
          else
            throw error "no export condition", reference.name, reference.version
        else
          rx[key] = value
    else if key.startsWith "#"
      # TODO process internal paths?
      continue
  rx

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
      exports: ->
        if @manifest.exports?
          if _.isString @manifest.exports
            ".": entry @manifest.exports
          else
            subpaths @
        else
          ".": entry @manifest.module ? @manifest.browser ?
            @manifest.main ? "index.js"

      resource: -> @_resource ?= Resource.create @
      scope: -> @resource.scope
      scopes: -> @resource.scopes
      map: -> ImportMap.create @
  ]

  glob: (pattern) -> micromatch @files, pattern

  capture: (pattern) ->
    r[0] for file in @files when (r = micromatch.capture pattern, file)?

  toString: -> @resource.specifier

export { Reference }
