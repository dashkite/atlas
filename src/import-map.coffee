import Path from "path"
import * as _ from "@dashkite/joy"
import { Scope, ParentScope } from "./scope"

optimize = (dependencies) ->

  results = new Set

  root = Scope.create "root"

  for dependency from dependencies
    self = Scope.create dependency
    parent = ParentScope.create dependency

    for _dependency from dependency.dependencies

      if root.has _dependency || parent.has _dependency
        continue

      if root.canAdd _dependency
        root.add _dependency
      else if parent.canAdd _dependency
        parent.add _dependency
      else
        self.add _dependency

    results.add self unless _.isEmpty self
    results.add parent unless _.isEmpty parent

  results.add root unless _.isEmpty root
  results

buildExports = (dependency, url) ->
  r = {}
  for key, value of dependency.exports
    _key = key.replace ".", dependency.name
    r[ _key ] = value.replace "./", url
  r

buildImports = (reference, url) ->
  if !_.isEmpty reference.aliases
    r = {}
    for key, value of reference.aliases
      r[ key ] = value.replace "./", url
    r

build = (scope, generator) ->
  r = {}
  for dependency from scope.dependencies
    _.assign r, buildExports dependency, generator dependency
  r

softMerge = (object, key, value) ->
  object[key] = _.merge (object[key] ? {}), value

sortObject = ( object ) ->
  addToImports = ( result, key ) ->
    result[ key ] = object[ key ]
    result

  ( Object.keys object )
    .sort()
    .reduce addToImports, {}

class ImportMap

  # set of instances of ImportMap
  @maps: new Map

  @create: (reference) ->
    if @maps.has reference
      @maps.get reference
    else
      @maps.set reference,
        result = _.assign new @, reference: reference
      result

  constructor: ->
    # set of import maps as JSON for this ImportMap
    @maps = new Map

  toJSON: (generator) ->

    result =
      imports: buildExports @reference, "/"
      scopes: {}

    for scope from optimize @reference.scopes
      if scope.reference == "root"
        _.assign result.imports, build scope, generator
      else
        result.scopes[ generator scope ] = build scope, generator

    for reference from @reference.scopes
      if !(_.isEmpty reference.aliases)
        if reference == @reference
          softMerge result.scopes, "/", buildImports @reference, "/"
        else
          softMerge result.scopes, (generator reference),
            buildImports reference, generator reference

    # maintain sort order for diffing
    result.imports = sortObject result.imports
    result.scopes = sortObject result.scopes
    for key, scope in result.scopes
      result.scopes[ key ] = sortObject scope

    JSON.stringify result, null, 2

export { ImportMap }
