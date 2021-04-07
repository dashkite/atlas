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

export { optimize }
