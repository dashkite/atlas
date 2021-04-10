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

class ModuleReference extends Reference

  @create: (name, range = "latest") -> _.assign (new @), {name, range}

  load: ->
    @manifest = await loadManifest @name, @range
    @files = await loadFiles @name, @version

  export: (generator, path) -> generator.fileURL {@name, @version, path}

  _.mixin @::, [
    _.getters
      description: -> @range
  ]

_.generic Reference.conflict,
  (_.isType ModuleReference), (_.isType ModuleReference),
  (a, b) -> (a.name == b.name) && !(Reference.similar a, b)

_.generic Reference.similar,
  (_.isType ModuleReference), (_.isType ModuleReference),
  (a, b) ->
    (a.name == b.name) &&
      ((semver.satisfies a.version, b.range) ||
        (semver.satisfies b.version, a.range))

_.generic Reference.choose,
  (_.isType ModuleReference), (_.isType ModuleReference),
  (a, b) ->
    if (semver.gt a.version, b.version) && (semver.satisfies a.version, b.range)
      a
    else if (semver.satisfies b.version, a.range)
      b
    else throw error "reference conflict", a, b

export { ModuleReference }
