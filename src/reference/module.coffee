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
  _.mixin @::, [
    _.getters
      description: -> @range
      manifest: -> @_manifest ?= load @name, @range
  ]

export { ModuleReference }
