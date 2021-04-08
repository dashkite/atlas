import semver from "semver"
import * as _ from "@dashkite/joy"
import { fetchJSON } from "../helpers"
import { Reference } from "./reference"

class WebReference extends Reference

  @create: (name, url) -> _.assign (new @), {name, url}

  load: -> @manifest = fetchJSON @url

  exports: (generator) -> generator.fileURL @

  _.mixin @::, [
    _.getters
      description: -> @url
  ]

export { WebReference }
