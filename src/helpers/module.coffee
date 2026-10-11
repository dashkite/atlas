import Path from "node:path"
import Zephyr from "@dashkite/zephyr"

cache = {}

normalize = ({ name, version, path }) ->
  specifier = name
  if name.startsWith "@"
    [ scope, packageName ] = name.split "/"
    { scope, name: packageName, specifier, version, path }
  else
    { name, specifier, version, path }

resolvePaths = ( current, cwd ) ->
  modulePath = Path.join current, "package.json"
  diskPath = if cwd != "." then Path.join cwd, modulePath else modulePath
  { modulePath, diskPath }

readPackage = ( diskPath ) ->
  if await Zephyr.exists diskPath
    return Zephyr.read diskPath
  null

loadPackage = ( current, cwd ) ->
  { modulePath, diskPath } = resolvePaths current, cwd
  data = await readPackage diskPath
  if data?
    return normalize { data..., path: Path.dirname modulePath }
  null

_read = ( path, cwd = "." ) ->
  current = path

  # Traverse up the directory tree to find the nearest package.json
  until ( current == "." ) || ( current == "/" ) || ( current == "" )
    current = Path.dirname current
    manifest = await loadPackage current, cwd
    if manifest?
      return manifest

  throw new Error "No module path found for #{ path }"

Module =
  initialize: ->
    cache = {}
    return

  read: ( path, cwd = "." ) ->
    cacheKey = if cwd != "." then "#{ cwd }:#{ path }" else path
    cache[ cacheKey ] ?= _read path, cwd

export { Module }
export default Module