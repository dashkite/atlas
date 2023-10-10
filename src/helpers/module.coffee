import Path from "node:path"

import * as Fn from "@dashkite/joy/function"
import Zephyr from "@dashkite/zephyr"

normalize = ({ name, version, path }) ->
  do ({ specifier } = {}) ->
    specifier = name
    if name.startsWith "@"
      [ scope, name ] = name[1..].split "/"
      { scope, name, specifier, version, path }
    else { name, specifier, version, path }

Module =

  read: Fn.memoize ( path ) ->
    current = path
    until current == "."
      current = Path.dirname current
      module = Path.join current, "package.json"
      if ( data = await Zephyr.read module )?
        return normalize { data..., path: Path.dirname module }
    throw new Error "No module path found for #{ path }"


export { Module }
export default Module