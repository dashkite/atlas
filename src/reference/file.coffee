import F from "fs/promises"
import P from "path"
import { fileURLToPath as _fileURLToPath } from "url"
import * as _ from "@dashkite/joy"
import fglob from "fast-glob"
import { Reference } from "./reference"

# you've got to be kidding me...
isFileLike = ( reference ) ->
  ( reference.startsWith "file:." ) ||
    ( reference.startsWith "link:."  )

getPathFromReference = ( reference ) ->
  # WARNING this just happens to work because file/link both have 4 char
  reference[5..]

fileURLToPath = ( reference ) ->
  if ( isFileLike reference ) then getPathFromReference reference
  else _fileURLToPath reference

class FileReference extends Reference

  @create: (name, url) -> _.assign (new @), {name, url}

  load: ->
    @manifest = JSON.parse await F.readFile @path, "utf8"
    # TODO read .gitignore to get list of exclusions?
    # TODO we could use package.json files list also?
    @files = await fglob [ "**", "!package-lock.json", "!node_modules/**" ],
      cwd: P.dirname @path

  export: (generator, path) -> generator.filePath {@name, @version, path}

  _.mixin @::, [
    _.getters
      description: -> @url
      path: ->  P.join (fileURLToPath @url), "package.json"
      directory: -> fileURLToPath @url
  ]

# equality for file references just means
# they are the same path
_.generic Reference.equal,
  (_.isType FileReference), (_.isType FileReference),
  (a, b) -> (a.path == b.path)

export { FileReference }
