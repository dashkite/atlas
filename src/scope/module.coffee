import * as _ from "@dashkite/joy"
import { Scope } from "./scope"
import { NameScope } from "./name"

class ModuleScope extends Scope
  @create: (reference) ->
    _.assign new @, {reference}

  _.mixin @::, [
    _.getters
      name: -> @reference.name
      version: -> @reference.version
      specifier: -> "#{@reference.name}@#{@reference.version}"
      dependencies: -> @reference.dependencies
  ]
export { ModuleScope }
