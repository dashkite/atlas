import Path from "node:path"

import * as Fn from "@dashkite/joy/function"
import Zephyr from "@dashkite/zephyr"

cache = {}

normalize = ({ name, version, path }) ->
  do ({ specifier } = {}) ->
    specifier = name
    if name.startsWith "@"
      [ scope, name ] = name[1..].split "/"
      { scope, name, specifier, version, path }
    else { name, specifier, version, path }

_read = ( path, cwd = "." ) ->
  current = path
  until current == "."
    current = Path.dirname current
    module = Path.join current, "package.json"
    diskPath = if cwd != "." then Path.join( cwd, module ) else module
    if ( data = await Zephyr.read diskPath )?
      return normalize { data..., path: Path.dirname module }
  throw new Error "No module path found for #{ path }"

Module =

  initialize: ->
    Zephyr.clear()
    cache = {}

  read: ( path, cwd = "." ) ->
    cacheKey = if cwd != "." then "#{ cwd }:#{ path }" else path
    cache[ cacheKey ] ?= _read path, cwd

export { Module }
export default Module