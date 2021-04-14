import P from "path"
import semver from "semver"
import * as _ from "@dashkite/joy"
import micromatch from "micromatch"
import { ModuleScope } from "../scope"
import { ImportMap } from "../import-map"
import { error } from "../errors"

class Reference

  # variants defined by subtypes
  @equal: _.generic
    name: "Reference.equal",
    description: "Returns true if two references are semantically equal."
    # defaults to strict equality
    default: (a, b) -> a == b

  _.mixin @::, [
    _.getters
      version: -> @manifest.version
      exports: -> @_exports ?= exports @
      aliases: -> @_locals ?= aliases @
      scopes: ->
        @_scopes ?= do =>
          r = new Set
          r.add @
          for d from @dependencies
            for s from d.scopes
              r.add s
          r
      map: -> @_map ?= ImportMap.create @
  ]

  glob: (pattern) -> micromatch @files, pattern

  capture: (pattern) ->
    r for file in @files when (r = capture pattern, file)

  toString: -> "[#{@name}@#{@version}]"


#
# Helpers for private generics `exports` and `aliases`
# used to implement exports and aliases properties
#

isReference = _.isKind Reference

hasExportsObject = (reference) ->
  (isReference reference) && _.isObject reference.manifest.exports

hasExportsString = (reference) ->
  (isReference reference) && _.isString reference.manifest.exports

hasImportsObject = (reference) ->
  (isReference reference) && _.isObject reference.manifest.imports

hasImportsString = (reference) ->
  (isReference reference) && _.isString reference.manifest.imports

isRelativePath = (path) ->
  (_.isString path) && path.startsWith "."

isWildCardPath = (path) ->
  (isRelativePath path) && (path.endsWith "*")

isAliasPath = (path) ->
  (_.isString path) && path.startsWith "#"

isAliasWildCardPath = (path) ->
  (isAliasPath path) && (path.endsWith "*")

entry = (path) ->
  if path.startsWith "."
    path
  else
    "./#{path}"

#
# exports private generic
#

exports = _.generic
  name: "exports"
  description: "Return relative exports for a module"
  # TODO should we warn of a possible error here?
  default: -> {}

#
# trivial case: two relative paths, just return them as a mapping
# wild-cards are handled in subsequent generics that will match
# before this one...
_.generic exports,
  isReference, isRelativePath, isRelativePath,
  (reference, from, to) ->
    [from]: to

#
# if we get an object, attempt to generate a mapping using the `import`
# property, and throw if we don't find one
#
# TODO do we need to throw? or does that just mean we should ignore it?
#
_.generic exports,
  isReference, isRelativePath, _.isObject,
  (reference, from, to) ->
    if to.import?
      exports reference, from, to.import
    else
      throw error "no import condition", reference

#
# for a wildcard path, we use the target pattern to
# match agains the files using the capture method
# the target pattern should be a glob but we don't
# check for that
#
_.generic exports,
  isReference, isWildCardPath, isRelativePath,
  (reference, from, to) ->
    rx = {}
    for path in reference.capture to
      rx[ (from.replace "*", path) ] = to.replace "*", path
    rx

# these next three are entry points for the generic, via
# `exports` property implementation above

#
# if we get here, it's because there's no exports object or string
#
_.generic exports, isReference, ({manifest}) ->
  ".": entry (manifest.module ? manifest.browser ?
    manifest.main ? "index.js")

#
# if we get an object, iterate through the properties and generate
# exports for each, merging the results into a single object
#
_.generic exports, hasExportsObject, (reference) ->
  _.merge (
    for key, value of reference.manifest.exports
      exports reference, key, value
  )...

#
# if we get a string, generate the mapping for .
#
_.generic exports, hasExportsString, (reference) ->
  ".": entry reference.manifest.exports

#
# aliases private generic
#

# similar to the exports generic, but with a few differences

# TODO how to handle aliases for package specifiers?
#      (since these need to be mapped later into URLs)

aliases = _.generic
  name: "aliases"
  description: "Return the aliases (internal imports) for a module"
  default: -> {}

#
# the trivial case, just generate a single mapping
# we don't check for relative path for the target
# because it could be a package specifier
_.generic aliases,
  isReference, isAliasPath, _.isString,
  (reference, from, to) ->
    [from]: to

#
# if we get an object, attempt to generate a mapping using the `import`
# property, and throw if we don't find one
#
# TODO do we need to throw? or does that just mean we should ignore it?
#
_.generic aliases,
  isReference, isAliasPath, _.isObject,
  (reference, from, to) ->
    if to.import?
      aliases reference, from, to.import
    else
      throw error "no import condition", reference

#
# for a wildcard path, we use the target pattern to
# match agains the files using the capture method
# the target pattern should be a glob but we don't
# check for that
#
_.generic aliases,
  isReference, isAliasWildCardPath, _.isString,
  (reference, from, to) ->
    rx = {}
    for path in reference.capture to
      rx[ (from.replace "*", path) ] = to.replace "*", path
    rx

#
# entry point for the function, via the `aliases` property
#
# if aliases exists, we should get an object
# so we iterate through the properties and generate
# exports for each, merging the results into a single object
#
# if there's no aliases property, we fall thru to the default
# which just returns an empty object
_.generic aliases, hasImportsObject, (reference) ->
  _.merge (
    for key, value of reference.manifest.imports
      aliases reference, key, value
  )...

#
# helper for the capture method, adapting micromatch to handle
# relative paths, which for some reason it doesn't already do
#
capture = (pattern, file) ->
  matches = micromatch.capture (pattern.replace "*", "**/*"),
    file.replace /^\.\//, ""
  if matches?
    [directory, basename] = matches
    if directory == ""
      basename
    else
      P.join directory, basename

export { Reference }
