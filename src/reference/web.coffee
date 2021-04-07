import semver from "semver"
import * as _ from "@dashkite/joy"
import { fetchJSON } from "../helpers"
import { Reference } from "./reference"

class WebReference extends Reference
  @create: (name, url) -> _.assign (new @), {name, url}
  _.mixin @::, [
    _.getters
      description: -> @url
      manifest: -> @_manifest ?= fetchJSON @url
  ]

export { WebReference }
