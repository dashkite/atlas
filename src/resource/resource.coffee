import * as _ from "@dashkite/joy"
import { error } from "../errors"

class Resource
  _.mixin @::, [
    _.getters
      version: -> @manifest.version
      specifier: -> "#{name}@#{version}"
  ]

export { Resource }
