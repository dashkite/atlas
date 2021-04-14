import * as _ from "@dashkite/joy"
import { Reference } from "./reference"

class Scope

  @create: (name) -> _.assign new @, {name, dependencies: new Set}

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

export { Scope }
