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

dictionary = (generator, scope) ->
  result = {}
  for d from scope.dependencies
    result[ d.name ] = d.exports generator
  result

class ImportMap

  @create: (scopes) ->
    _.assign new @,
      scopes: optimize scopes

  toJSON: (generator) ->
    result = {}
    for scope from @scopes
      if scope.name == "root"
        result.imports = dictionary generator, scope
      else
        (result.scopes ?= {})[ generator.scopeURL scope ] =
          dictionary generator, scope
    JSON.stringify result, null, 2


export { ImportMap }
