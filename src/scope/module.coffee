import * as _ from "@dashkite/joy"
import { Scope } from "./scope"

class ModuleScope extends Scope
  @create: (resource) ->
    dependencies = await resource.dependencies
    _.assign new @, {resource, dependencies}

export { ModuleScope }
