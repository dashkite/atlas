import semver from "semver"
import * as _ from "@dashkite/joy"
import { fetchJSON } from "../helpers"
import { error } from "../errors"
import { Resource } from "./resource"

manifests = do (cache = {}) ->
  (name) ->
    cache[name] ?= await fetchJSON "https://registry.npmjs.org/#{name}"

resolve = (name, range = "latest") ->
  p = await manifests name
  if range == "latest"
    p["dist-tags"].latest
  else
    # the order of the manifests appears to be sorted by version already
    (Object.keys p.versions)
      .reverse()
      .find (v) => semver.satisfies v, range

class ModuleResource extends Resource
  @create: (name, range) -> _.assign (new @), {name, range}
  load: ->
    version = await resolve @name, @range
    url = "https://registry.npmjs.org/#{@name}/#{version}"
    @manifest = await fetchJSON url

export { ModuleResource }
