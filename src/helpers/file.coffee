import Path from "node:path"
import FS from "node:fs/promises"

import * as Fn from "@dashkite/joy/function"

split = ( path ) -> path.split Path.sep

join = ( components ) -> components.join Path.sep

read = Fn.memoize ( path ) ->
  await FS.readFile path, "utf8"

exists = Fn.memoize ( path ) ->
  try
    await read path
    true
  catch
    false

Directory =

  contains: ( folder, path ) ->
    (( split path ).find ( component ) -> component == folder )?

  within: ( directory, path ) ->
    !(( Path.relative directory, path ).startsWith "." )


export {
  split
  join
  read
  exists
  Directory
}