import * as _ from "@dashkite/joy"
import { Scope } from "./scope"

class NameScope extends Scope

  @create: (scope) ->
    _.assign new @,
      name: scope.name
      dependencies: (new Set)

  add: (item) -> @dependencies.add item

  delete: (item) -> @dependencies.delete item

  has: (item) -> @dependencies.has item

export { NameScope }
