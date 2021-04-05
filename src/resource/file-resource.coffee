import F from "fs/promises"
import P from "path"
import { fileURLToPath as _fileURLToPath } from "url"
import * as _ from "@dashkite/joy"
import { Resource } from "./resource"

# you've got to be kidding me...
fileURLToPath = (s) ->
  if s.startsWith "file:." then P.resolve s[5..]
  else _fileURLToPath s

class FileResource extends Resource
  @create: (name, url) ->_.assign (new @), {name, url}
  _.mixin @::, [
    _.getters
      path: ->  P.join (fileURLToPath @url), "package.json"
  ]
  load: -> @manifest = JSON.parse await F.readFile @path, "utf8"

export { FileResource }
