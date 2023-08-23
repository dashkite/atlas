import Path from "node:path"
import FS from "node:fs/promises"

import * as Fn from "@dashkite/joy/function"

import {
  join
  read
  exists
} from "./file"

readModuleInfo = Fn.memoize ( path ) ->
  { name, version } = JSON.parse await read Path.join path, "package.json"
  if name.startsWith "@"
    [ scope, name ] = name[1..].split "/"
    { scope, name, version, path }
  else { name, version, path }

getModulePath = Fn.memoize ( path ) ->
  directory = Path.dirname Path.resolve path
  until directory == "."
    if await exists Path.join directory, "package.json"
      return directory
    directory = Path.dirname directory
  throw new Error "No module path found for #{ path }"

getModuleInfo = Fn.flow [
  getModulePath
  readModuleInfo
]

export {
  readModuleInfo
  getModulePath
  getModuleInfo
}