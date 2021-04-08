import * as _ from "@dashkite/joy"
import { error } from "./errors"

jsdelivr =

  fileURL: (reference) ->
    {name, version, paths} = reference
    if _.isString paths["."]
      "https://cdn.jsdelivr.net/npm/#{name}@#{version}/#{paths['.']}"
    else
      throw error "exports conditions", name, version

  filePath: (reference) ->
    {name, version, paths} = reference
    if _.isString paths["."]
      "/node_modules/#{name}@#{version}/#{paths['.']}"
    else
      throw error "exports conditions", name, version

  scopeURL: ({name}) ->
    "https://cdn.jsdelivr.net/npm/#{name}"

export {jsdelivr}
