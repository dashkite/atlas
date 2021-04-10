import * as _ from "@dashkite/joy"
import { NameScope } from "./scope"

optimize = (scopes) ->

  results = new Set

  root = NameScope.create "root"

  for scope from scopes

    self = NameScope.create scope.specifier
    parent = NameScope.create scope.name

    for dependency from scope.dependencies

      if root.has dependency || parent.has dependency
        continue

      if root.canPlace dependency
        root.place dependency
      else if parent.canPlace dependency
        parent.place dependency
      else
        self.add dependency

    results.add self unless _.isEmpty self
    results.add parent unless _.isEmpty parent

  results.add root unless _.isEmpty root
  results

_dictionary = (generator, reference) ->
  result = {}
  url = generator reference
  console.log reference, url
  for key, value of reference.exports
    result[ (key.replace ".", reference.name) ] = value.replace ".", url
  result

dictionary = (generator, scope) ->
  result = {}
  for d from scope.dependencies
    url = generator d
    for key, value of d.exports
      result[ (key.replace ".", d.name) ] = value.replace ".", url
  result

class ImportMap

  @create: (reference) ->
    _.assign new @,
      reference: reference

  toJSON: (generator) ->
    result = imports: _dictionary generator, @reference
    for scope from optimize @reference.scopes
      if scope.name == "root"
        _.assign result.imports, dictionary generator, scope
      else
        (result.scopes ?= {})[ generator scope ] =
          dictionary generator, scope
    JSON.stringify result, null, 2


export { ImportMap }
