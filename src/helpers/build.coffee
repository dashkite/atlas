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

Build =
  decorator: Fn.tee ( dependency ) ->
    dependency.module.hash =
      ( await getBuildInfo dependency )?.module.hash
    dependency.import.scope.module.hash =
      ( await getBuildInfo dependency.import.scope )?.module.hash

export {
  readBuildInfo
  getHash
  getBuildInfo
  Build
}