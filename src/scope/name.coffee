import * as _ from "@dashkite/joy"
import { Scope } from "./scope"
import { Reference } from "../reference"

class NameScope extends Scope

  @create: (name) -> _.assign new @, {name, dependencies: new Set}

  _.mixin @::, [
    _.getters
      size: -> @dependencies.size
  ]

  has: (d) -> @dependencies.has d

  add: (d) -> @dependencies.add d

  delete: (d) -> @dependencies.delete d

  canPlace: (d) ->
    for _d from @dependencies
      if (Reference.conflict d, _d)
        return false
      else if (Reference.similar d, _d)
        return true
    return true

  place: (d) ->
    for _d from @dependencies
      if (Reference.similar d, _d)
        d = Reference.choose d, _d
        if d != _d
          @delete _d
          @add d
        return @dependencies
    @dependencies.add d

export { NameScope }
