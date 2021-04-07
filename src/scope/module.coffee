import * as _ from "@dashkite/joy"
import { Scope } from "./scope"

class ModuleScope extends Scope
  @create: (resource) ->
    {dependencies} = resource
    _.assign new @, {resource, dependencies}

export { ModuleScope }
