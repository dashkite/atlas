import P from "path"
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
      exports: -> @_exports = exports @
      aliases: -> @_locals = aliases @
      # scope: -> @ # @_scope ?= ModuleScope.create @
      scopes: ->
        @_scopes ?= do =>
          r = new Set
          r.add @
          for d from @dependencies
            for s from d.scopes
              r.add s
          r

      map: -> ImportMap.create @
  ]

  glob: (pattern) -> micromatch @files, pattern

  capture: (pattern) ->
    r for file in @files when (r = capture pattern, file)

  toString: -> @resource.specifier

capture = (pattern, file) ->
  matches = micromatch.capture (pattern.replace "*", "**/*"),
    file.replace /^\.\//, ""
  if matches?
    [directory, basename] = matches
    if directory == ""
      basename
    else
      P.join directory, basename

entry = (path) ->
  if path.startsWith "."
    path
  else
    "./#{path}"

isRelativePath = (path) ->
  (_.isString path) && path.startsWith "."

isWildCardPath = (path) ->
  (isRelativePath path) && (path.endsWith "*")

isAliasPath = (path) ->
  (_.isString path) && path.startsWith "#"

isAliasWildCardPath = (path) ->
  (isAliasPath path) && (path.endsWith "*")

isReference = _.isKind Reference

hasExportsObject = (reference) ->
  (isReference reference) && _.isObject reference.manifest.exports

hasExportsString = (reference) ->
  (isReference reference) && _.isString reference.manifest.exports

hasImportsObject = (reference) ->
  (isReference reference) && _.isObject reference.manifest.imports

hasImportsString = (reference) ->
  (isReference reference) && _.isString reference.manifest.imports

exports = _.generic
  name: "exports"
  description: "Return relative exports for a module"
  # TODO should we warn of a possible error here?
  default: -> {}

_.generic exports,
  isReference, isRelativePath, _.isString,
  (reference, from, to) ->
    [from]: to

_.generic exports,
  isReference, isRelativePath, _.isObject,
  (reference, from, to) ->
    if to.import?
      exports reference, from, to.import
    else
      throw error "no import condition",
        reference.name, reference.version

_.generic exports,
  isReference, isWildCardPath, _.isString,
  (reference, from, to) ->
    rx = {}
    for path in reference.capture to
      rx[ (from.replace "*", path) ] = to.replace "*", path
    rx

_.generic exports, isReference, ({manifest}) ->
  ".": entry (manifest.module ? manifest.browser ?
    manifest.main ? "index.js")

_.generic exports, hasExportsObject, (reference) ->
  _.merge (
    for key, value of reference.manifest.exports
      exports reference, key, value
  )...

_.generic exports, hasExportsString, (reference) ->
  ".": entry reference.manifest.exports

aliases = _.generic
  name: "aliases"
  description: "Return the aliases (internal imports) for a module"
  # TODO should we warn of a possible error here?
  default: -> {}

_.generic aliases, hasImportsObject, (reference) ->
  _.merge (
    for key, value of reference.manifest.imports
      aliases reference, key, value
  )...

_.generic aliases,
  isReference, isAliasPath, _.isObject,
  (reference, from, to) ->
    if to.import?
      aliases reference, from, to.import
    else
      throw error "no import condition",
        reference.name, reference.version

_.generic aliases,
  isReference, isAliasPath, _.isString,
  (reference, from, to) ->
    [from]: to

_.generic aliases,
  isReference, isAliasWildCardPath, _.isString,
  (reference, from, to) ->
    rx = {}
    for path in reference.capture to
      rx[ (from.replace "*", path) ] = to.replace "*", path
    rx

export { Reference }
