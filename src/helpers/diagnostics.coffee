import FS from "node:fs/promises"
import Path from "node:path"
import { isSet, isMap, isSymbol } from "@dashkite/joy/type"

normalize = ( value ) ->
  if isSet value
    Array.from value
  else if isMap value
    Object.fromEntries value
  else if isSymbol value
    value.toString()
  else
    value

replacer = ( key, value ) ->
  if key == "parent"
    undefined
  else
    normalize value

serialize = ( value ) ->
  JSON.stringify value, replacer, 2

resolveDirectory = ( kind, entries ) ->
  basename = Path.basename entries[ 0 ], Path.extname entries[ 0 ]
  Path.join process.cwd(), ".atlas", kind, basename

writeFile = ( directory ) ->
  ([ filename, data ]) ->
    FS.writeFile ( Path.join directory, filename ), serialize data

write = ( directory, artifacts ) ->
  await FS.mkdir directory, recursive: true
  tasks = ( Object.entries artifacts ).map writeFile directory
  await Promise.all tasks
  return

dump = ( kind, select ) ->
  ( context ) ->
    if process.env.DEBUG
      try
        directory = resolveDirectory kind, context.entries
        await write directory, select context.pipeline
      catch error
        console.warn "Atlas DEBUG: Failed to write debug files:", error
    context

export default { dump }
export { dump }
