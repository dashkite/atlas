import * as _ from "@dashkite/joy"

import { Reference } from "./reference"

import { FileReference } from "./file"
import { WebReference } from "./web"
import { RegistryReference } from "./registry"

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

loadDependencies = (reference) ->
  {manifest} = reference
  reference.dependencies ?= await do ->
    r = new Set
    await Promise.all (
      for name, description of manifest.dependencies
        do -> r.add await Reference.create name, description
    )
    r

Reference.create = _.memoize (name, description) ->
  reference = if (url = parseURL description)?
    createFromURL name, description, url
  else
    RegistryReference.create name, description
  await reference.load()
  await loadDependencies reference
  reference
