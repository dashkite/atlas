import * as _ from "@dashkite/joy"
import { FileReference } from "./reference/file"
import { Scope } from "./scope"
import { error } from "./errors"

jsdelivr = _.generic
  name: "jsdelivr"
  description: "jsdelivr URL generator"
  default: ({name, version}) ->
    "https://cdn.jsdelivr.net/npm/#{name}@#{version}"

_.generic jsdelivr, (_.isKind FileReference), ({name, version}) ->
  "/node_modules/#{name}"

_.generic jsdelivr, (_.isKind Scope), ({name}) ->
  "https://cdn.jsdelivr.net/npm/#{name}"

jspm = _.generic
  name: "jspm"
  description: "jsdelivr URL generator"
  default: ({name, version}) ->
    "https://ga.jspm.io/npm:#{name}@#{version}"

_.generic jspm, (_.isKind FileReference), ({name, version}) ->
  "/node_modules/#{name}"

_.generic jspm, (_.isKind Scope), ({name}) ->
  "https://ga.jspm.io/npm:#{name}"

export {
  jsdelivr
  jspm
}
