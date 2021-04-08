import F from "fs/promises"
import P from "path"
import { fileURLToPath as _fileURLToPath } from "url"
import * as _ from "@dashkite/joy"
import { Reference } from "./reference"

# you've got to be kidding me...
fileURLToPath = (s) ->
  if s.startsWith "file:." then P.resolve s[5..]
  else _fileURLToPath s

class FileReference extends Reference

  @create: (name, url) -> _.assign (new @), {name, url}

  load: -> @manifest = JSON.parse await F.readFile @path, "utf8"

  exports: (generator) -> generator.filePath @

  _.mixin @::, [
    _.getters
      description: -> @url
      path: ->  P.join (fileURLToPath @url), "package.json"
  ]

export { FileReference }
