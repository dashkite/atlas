import Path from "node:path"
import * as YAML from "js-yaml"

import * as Fn from "@dashkite/joy/function"
import * as Obj from "@dashkite/joy/object"
import Zephyr from "@dashkite/zephyr"

decorateModule = ( dependency ) ->
  { source, module } = dependency
  path = Path.join module.path, ".sky", "hashes.yaml"
  hashes = await Zephyr.read path
  if hashes?
    path = Path.relative module.path, source.path
    source.hash ?= hashes[ path ]

Build =

  decorator: Fn.tee ( dependency ) ->
    Promise.all [
      decorateModule dependency
      decorateModule dependency.import.scope
    ] 

export {
  readBuildInfo
  getBuildInfo
  Build
}