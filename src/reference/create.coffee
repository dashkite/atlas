import * as _ from "@dashkite/joy"

import { Reference } from "./reference"

import { FileReference } from "./file"
import { WebReference } from "./web"
import { ModuleReference } from "./module"

# Reference.create is defined separately from the Reference type
# because we need to import the subtypes for dynamic create.
# But each subtype extends Reference, so that would otherwise
# create a circular dependency.

handlers =
  file: FileReference
  http: WebReference
  git: create: -> throw error "git URL"

createFromURL = (name, description, url) ->
  protocol = url.protocol[...-1]
  if (handler = handlers[protocol])?
    handler.create name, description
  else
    throw error "unsupported protocol", protocol

parseURL = (s) -> try (new URL s)

Reference.create = _.memoize (name, description) ->
  if (url = parseURL description)?
    createFromURL name, description, url
  else
    ModuleReference.create name, description
