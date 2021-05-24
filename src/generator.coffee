import * as _ from "@dashkite/joy"
import { FileReference } from "./reference/file"
import { Scope } from "./scope"
import { error } from "./errors"

jsdelivr = _.generic
  name: "generator"
  description: "jsdelivr URL generator"
  default: ({name, version}) ->
    "https://cdn.jsdelivr.net/npm/#{name}@#{version}"

_.generic jsdelivr, (_.isKind FileReference), ({name, version}) ->
  "/node_modules/#{name}"

_.generic jsdelivr, (_.isKind Scope), ({name}) ->
  "https://cdn.jsdelivr.net/npm/#{name}"

export {jsdelivr}
