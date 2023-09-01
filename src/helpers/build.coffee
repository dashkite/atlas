import Path from "node:path"
import * as YAML from "js-yaml"

import * as Fn from "@dashkite/joy/function"
import * as Obj from "@dashkite/joy/object"
import Zephyr from "@dashkite/zephyr"

import { read } from "./file"


readBuildInfo = Fn.memoize ( path ) ->
  module: Obj.get "data",
    await Zephyr.read Path.join path, ".genie", "build.yaml"
  files: Obj.get "data",
    await Zephyr.read Path.join path, ".genie", "hashes.yaml"

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