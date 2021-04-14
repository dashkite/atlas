import semver from "semver"
import * as _ from "@dashkite/joy"
import { fetchJSON } from "../helpers"
import { error } from "../errors"
import { Reference } from "./reference"

# TODO set User-Agent for queries for the JSDelivr API
templates =

  metadata: (name) ->
    "https://data.jsdelivr.com/v1/package/npm/#{name}"

  manifest: (name, version) ->
    "https://cdn.jsdelivr.net/npm/#{name}@#{version}/package.json"

  files: (name, version) ->
    "https://data.jsdelivr.com/v1/package/npm/#{name}@#{version}/flat"

manifests = do (cache = {}) ->
  (name) -> cache[name] ?= await fetchJSON templates.metadata name

resolve = (name, range) ->
  p = await manifests name
  if range == "latest"
    p.tags.latest
  else
    # the order of the manifests that jsdelivr gives us
    # appear to be sorted by version already
    # so all we need to do is go through them in order
    if semver.validRange range
      if (version = p.versions.find (v) -> semver.satisfies v, range)?
        version
      else
        throw error "no version", name, range
    else
      throw error "invalid range", name, range

loadManifest = (name, range) ->
  version = await resolve name, range
  await fetchJSON templates.manifest name, version

loadFiles = (name, version) ->
  (await fetchJSON templates.files name, version)
  .files
  .map ({name}) -> name[1..]

class RegistryReference extends Reference

  @create: (name, range = "latest") -> _.assign (new @), {name, range}

  load: ->
    @manifest = await loadManifest @name, @range
    @files = await loadFiles @name, @version

  export: (generator, path) -> generator.fileURL {@name, @version, path}

  _.mixin @::, [
    _.getters
      description: -> @range
  ]

# equality for registry references just means
# they are the same module and version
_.generic Reference.equal,
  (_.isType RegistryReference), (_.isType RegistryReference),
  (a, b) -> (a.name == b.name) && (a.version == b.version)

export { RegistryReference }
