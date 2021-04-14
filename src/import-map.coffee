import * as _ from "@dashkite/joy"
import { Scope } from "./scope"

optimize = (scopes) ->

  results = new Set

  root = Scope.create "root"

  for scope from scopes

    # TODO this hardcodes the name@version convention
    #      before we've generated the URL
    self = Scope.create "#{scope.name}@#{scope.version}"
    parent = Scope.create scope.name

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


project = (fkey, url, _exports) ->
  result = {}
  for key, value of _exports
    result[ (fkey key) ] = value.replace ".", url
  result

resolve = (name) -> (key) -> key.replace ".", name

scopeExports = (scope, generator) ->
  _.merge (
    for dependency from scope.dependencies
      project (resolve dependency.name),
        (generator dependency),
        dependency.exports
    )...

class ImportMap

  @create: (reference) ->
    _.assign new @,
      reference: reference

  toJSON: (generator) ->

    # TODO I think we need to add the local exports here too
    result = imports:
      project (resolve @reference.name),
        (generator @reference),
        @reference.exports

    for scope from optimize @reference.scopes
      if scope.name == "root"
        _.assign result.imports, scopeExports scope, generator
      else
        (result.scopes ?= {})[ generator scope ] =
          scopeExports scope, generator

    for scope from @reference.scopes
      if !_.isEmpty scope.aliases
        (result.scopes ?= {})[ generator scope ] =
          project _.identity,
            (generator scope),
            scope.aliases
    result

    JSON.stringify result, null, 2


export { ImportMap }
