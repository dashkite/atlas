import Path from "node:path"
import Zephyr from "@dashkite/zephyr"

cache = {}

normalize = ({ name, version, path }) ->
  specifier = name
  if name.startsWith "@"
    [ scope, pkgName ] = name[1..].split "/"
    { scope, name: pkgName, specifier, version, path }
  else 
    { name, specifier, version, path }

_read = ( path, cwd = "." ) ->
  current = path
  
  # Traverse up the directory tree to find the nearest package.json
  until current == "." || current == "/" || current == ""
    current = Path.dirname current
    modulePath = Path.join current, "package.json"
    diskPath = if cwd != "." then Path.join( cwd, modulePath ) else modulePath
    
    try
      data = await Zephyr.read diskPath
      if data? && data.name?
        return normalize { data..., path: Path.dirname modulePath }
    catch
      # ignore missing or invalid package.json
      
  throw new Error "No module path found for #{ path }"

Module =
  initialize: ->
    cache = {}

  read: ( path, cwd = "." ) ->
    cacheKey = if cwd != "." then "#{ cwd }:#{ path }" else path
    cache[ cacheKey ] ?= _read path, cwd

export { Module }
export default Module
