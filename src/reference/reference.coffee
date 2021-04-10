import semver from "semver"
import * as _ from "@dashkite/joy"
import micromatch from "micromatch"
import { ModuleScope } from "../scope"
import { ImportMap } from "../import-map"
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
      exports: ->
        if @manifest.exports?
          if _.isString @manifest.exports
            ".": entry @manifest.exports
          else
            subpaths @
        else
          ".": entry @manifest.module ? @manifest.browser ?
            @manifest.main ? "index.js"

      scope: -> @_scope ?= ModuleScope.create @
      scopes: ->
        @_scopes ?= do =>
          r = new Set
          r.add @scope
          for d from @dependencies
            for s from d.scopes
              r.add s
          r

      map: -> ImportMap.create @
  ]

  glob: (pattern) -> micromatch @files, pattern

  capture: (pattern) ->
    r[0] for file in @files when (r = micromatch.capture pattern, file)?

  toString: -> @resource.specifier


entry = (path) ->
  if path.startsWith "."
    path
  else
    "./#{path}"

isWildCard = (path) ->
  (_.isString path) && (path.startsWith ".") && (path.endsWith "*")

isReference = _.isKind Reference

subpath = _.generic
  name: "subpath"
  description: "Return a mapping from a import/export pair"

_.generic subpath,
  isReference, _.isString, _.isString,
  (reference, from, to) ->
    [from]: to

_.generic subpath,
  isReference, _.isString, _.isObject,
  (reference, from, to) ->
    if to.import?
      subpath reference, from, to.import
    else
      throw error "no export condition",
        reference.name, reference.version

_.generic subpath,
  isReference, isWildCard, _.isString,
  (reference, from, to) ->
    rx = {}
    for path in reference.capture to.replace "*", "**"
      rx[ (from.replace "*", path) ] = to.replace "*", path
    rx

subpaths = (reference) ->
  _.merge (
    for key, value of reference.manifest.exports
      subpath reference, key, value
  )...

export { Reference }
