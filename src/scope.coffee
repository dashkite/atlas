import * as _ from "@dashkite/joy"
import { Reference } from "./reference"

class Scope

  @create: (reference) -> _.assign new @, {reference, dependencies: new Set}

  _.mixin @::, [
    _.getters
      size: -> @dependencies.size
  ]

  has: (d) ->
    (@dependencies.has d) || do =>
      for _d from @dependencies
        if Reference.equal d, _d
          return true
      false

  add: (d) -> @dependencies.add d

  canAdd: (d) ->
    for _d from @dependencies
      if (d.name == _d.name)
        return false
    return true

class ParentScope extends Scope

export { Scope, ParentScope }
