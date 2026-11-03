import Path from "node:path"
import Zephyr from "@dashkite/zephyr"

normalize = ({ name, version }, path ) ->
  name: name
  version: version
  path: if path == "." then "" else path

resolvePath = ( current, directory ) ->
  path = Path.join current, "package.json"
  if directory != "."
    Path.join directory, path
  else
    path

readPackage = ( path ) ->
  if await Zephyr.exists path
    Zephyr.read path
  else
    null

loadPackage = ( current, directory ) ->
  disk = resolvePath current, directory
  data = await readPackage disk
  if data?
    normalize data, current
  else
    null

isTerminal = ( path ) ->
  ( path == "." ) || ( path == "/" ) || ( path == "" )

_read = ( path, directory = "." ) ->
  current = path
  manifest = null
  until ( manifest? ) || ( isTerminal current )
    current = Path.dirname current
    manifest = await loadPackage current, directory
  if manifest?
    manifest
  else
    throw new Error "No module path found for #{ path }"

class ModuleCache
  @make: ( directory = "." ) ->
    Object.assign ( new @ ),
      directory: directory
      cache: {}

  read: ( path, directory = @directory ) ->
    key = if directory != "."
      "#{ directory }:#{ path }"
    else
      path
    @cache[ key ] ?= _read path, directory

export { ModuleCache }
export default ModuleCache