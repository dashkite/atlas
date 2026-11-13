import FS from "node:fs/promises"
import Module from "node:module"
import Path from "node:path"
import { pathToFileURL } from "node:url"

find = ( path ) ->
  resolved = await FS.realpath path
  ( Module.findPackageJSON pathToFileURL resolved ) ? null

read = ( directory ) ->
  try
    await FS.readFile Path.resolve directory, "package.json"
  catch error
    if error.code == "ENOENT"
      null
    else
      throw error

export default { find, read }
export { find, read }
