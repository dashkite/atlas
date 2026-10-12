import Path from "node:path"
import Zephyr from "@dashkite/zephyr"

cache = {}

normalize = ({ name, version, path }) ->
  specifier = name
  if name.startsWith "@"
    [ scope, name ] = name.split "/"
    { scope, name, specifier, version, path }
  else
    { name, specifier, version, path }

resolvePaths = ( current, directory ) ->
  path = Path.join current, "package.json"
  disk = if directory != "."
    Path.join directory, path
  else
    path
  { path, disk }

readPackage = ( path ) ->
  if await Zephyr.exists path
    return Zephyr.read path
  null

loadPackage = ( current, directory ) ->
  { path, disk } = resolvePaths current, directory
  data = await readPackage disk
  if data?
    return normalize { data..., path: Path.dirname path }
  null

_read = ( path, directory = "." ) ->
  current = path

  # Traverse up the directory tree to find the nearest package.json
  until ( ( ( current == "." ) || ( current == "/" ) ) || ( current == "" ) )
    current = Path.dirname current
    manifest = await loadPackage current, directory
    if manifest?
      return manifest

  throw new Error "No module path found for #{ path }"

Module =
  initialize: ->
    cache = {}
    return

  read: ( path, directory = "." ) ->
    key = if directory != "."
      "#{ directory }:#{ path }"
    else
      path
    cache[ key ] ?= _read path, directory

export { Module }
export default Module