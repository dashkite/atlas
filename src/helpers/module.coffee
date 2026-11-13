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

readPackage = ( current, directory ) ->
  path = resolvePath current, directory
  if await Zephyr.exists path
    normalize ( await Zephyr.read path ), current
  else
    null

isTerminal = ( path ) ->
  ( path == "." ) || ( path == "/" ) || ( path == "" )

_read = ( path, directory ) ->
  current = path
  manifest = null
  until ( manifest? ) || ( isTerminal current )
    current = Path.dirname current
    manifest = await readPackage current, directory
  if manifest?
    manifest
  else
    throw new Error "No module path found for #{ path }"

class ModuleCache
  @make: ( directory ) ->
    Object.assign ( new @ ),
      directory: directory
      cache: {}

  read: ( path ) ->
    @cache[ path ] ?= _read path, @directory

export { ModuleCache }
export default ModuleCache
