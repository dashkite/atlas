import * as _ from "@dashkite/joy"
import { Scope } from "./scope"
import { NameScope } from "./name"

class ModuleScope extends Scope
  @create: (resource) ->
    {dependencies} = resource
    _.assign new @, {resource, dependencies}

  _.mixin @::, [
    _.getters
      name: -> @resource.name
      version: -> @resource.version
      specifier: -> @resource.specifier
  ]
export { ModuleScope }
