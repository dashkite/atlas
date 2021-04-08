import semver from "semver"
import * as _ from "@dashkite/joy"
import { fetchJSON } from "../helpers"
import { error } from "../errors"
import { Reference } from "./reference"

manifests = do (cache = {}) ->
  (name) ->
    cache[name] ?= await fetchJSON "https://registry.npmjs.org/#{name}"

resolve = (name, range) ->
  p = await manifests name
  if range == "latest"
    p["dist-tags"].latest
  else
    # the order of the manifests appears to be sorted by version already
    (Object.keys p.versions)
      .reverse()
      .find (v) -> semver.satisfies v, range

load = (name, range) ->
  version = await resolve name, range
  url = "https://registry.npmjs.org/#{name}/#{version}"
  await fetchJSON url


class ModuleReference extends Reference

  @create: (name, range = "latest") -> _.assign (new @), {name, range}

  load: -> @manifest = await load @name, @range

  exports: (generator) -> generator.fileURL @

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
