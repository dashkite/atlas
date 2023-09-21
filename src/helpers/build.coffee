import Path from "node:path"
import * as YAML from "js-yaml"

import * as Fn from "@dashkite/joy/function"
import * as Obj from "@dashkite/joy/object"
import Zephyr from "@dashkite/zephyr"

lift = ( value ) -> value ? {}

read = ( path, name ) ->
  Zephyr.read Path.join path, ".genie", "#{ name }.yaml"

readBuildInfo = Fn.memoize ( path ) ->
  module: lift await read path, "build"
  files: lift await read path, "hashes"

getBuildInfo = ({ module }) -> readBuildInfo module.path

decorateModule = ( description ) ->
  do ({ module, source } = description ) ->
    info = await getBuildInfo description
    path = Path.relative module.path, source.path
    module.hash ?= info.module?.hash
    source.hash ?= info.files[ path ]

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