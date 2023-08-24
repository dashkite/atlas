import Path from "node:path"
import * as YAML from "js-yaml"

import * as Fn from "@dashkite/joy/function"

import { read } from "./file"

readBuildInfo = Fn.memoize ( path ) ->
  try
    YAML.load await read Path.join path, ".genie/build.yaml"
  catch
    {}

getHash = ( path ) -> ( await readBuildInfo path ).hash

getBuildInfo = ( description ) ->
  module:
    hash: await getHash description.module.path

decorateModule = ( description ) ->
  description.module.hash ?=
    ( await getBuildInfo description ).module.hash

Build =

  decorator: Fn.tee ( dependency ) ->
    Promise.all [
      decorateModule dependency
      decorateModule dependency.import.scope
    ] 

export {
  readBuildInfo
  getHash
  getBuildInfo
  Build
}