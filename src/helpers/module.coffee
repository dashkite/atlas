import Path from "node:path"
import FS from "node:fs/promises"

import * as Fn from "@dashkite/joy/function"

import {
  join
  read
  exists
} from "./file"

getModulePath = Fn.memoize ( path ) ->
  loop
    current = Path.dirname current ? path
    if await exists Path.join current, "package.json"
      break
    else if current == "."
      throw new Error "No module path found for #{ path }"
  current

readModuleInfo = Fn.memoize ( path ) ->
  { name, version } = JSON.parse await read Path.join path, "package.json"
  specifier = name
  if name.startsWith "@"
    [ scope, name ] = name[1..].split "/"
    { scope, name, specifier, version, path }

  else { name, specifier, version, path }


getModuleInfo = Fn.flow [
  getModulePath
  readModuleInfo
]

export {
  readModuleInfo
  getModulePath
  getModuleInfo
}