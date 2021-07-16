import Path from "path"
import * as _ from "@dashkite/joy"
import { FileReference } from "./reference/file"
import { Scope, ParentScope } from "./scope"
import { error } from "./errors"

local = _.pipe [
  _.split "/"
  _.second
]

jsdelivr = _.generic
  name: "jsdelivr"
  description: "jsdelivr URL generator"
  default: ({name, version}) ->
    "https://cdn.jsdelivr.net/npm/#{name}@#{version}/"

_.generic jsdelivr, _.isString, (name) ->
  "https://cdn.jsdelivr.net/npm/#{name}/"

_.generic jsdelivr, (_.isKind FileReference), ({name}) ->
  "/#{local name}/"

_.generic jsdelivr, (_.isKind Scope), ({reference}) -> jsdelivr reference

_.generic jsdelivr, (_.isKind ParentScope), ({reference}) ->
  # hacky AF but just need to get this working
  # amounts to a no-op for file references
  (jsdelivr reference).replace "@#{reference.version}", ""

export {
  jsdelivr
}
