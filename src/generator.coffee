import * as _ from "@dashkite/joy"
import { FileReference } from "./reference/file"
import { NameScope } from "./scope"
import { error } from "./errors"

jsdelivr = _.generic
  name: "generator"
  description: "jsdelivr URL generator"
  default: ({name, version}) ->
    "https://cdn.jsdelivr.net/npm/#{name}@#{version}"

_.generic jsdelivr, (_.isKind FileReference), ({name, version}) ->
  "/node_modules/#{name}@#{version}/"

_.generic jsdelivr, (_.isKind NameScope), ({name}) ->
  "https://cdn.jsdelivr.net/npm/#{name}"

export {jsdelivr}
