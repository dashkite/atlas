import { Resource } from "./resource"
import { FileResource } from "./file-resource"
import { WebResource } from "./web-resource"
import { ModuleResource } from "./module-resource"

# Resource.create is defined separately from the Resource type
# because we need to import the subtypes for dynamic create.
# But each subtype extends Resource, so that would otherwise
# create a circular dependency.

parseURL = (s) -> try (new URL s)

_create = (name, qualifier) ->
  resource = if (url = parseURL qualifier)?
    url = parseURL qualifier
    switch url.protocol[...-1]
      when "file" then FileResource.create name, qualifier
      when "http", "https" then WebResource.create name, qualifier
      when "git" then throw error "git URL"
      else throw error "unsupported protocol", url.protocol[...-1]
  else
    ModuleResource.create name, qualifier
  await resource.load()
  resource

Resource.create = do (cache = {}) ->
  (name, qualifier) ->
    cache["#{name}@#{qualifier}"] ?= _create name, qualifier

export { Resource }
