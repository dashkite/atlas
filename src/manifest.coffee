import fetch from "node-fetch"
import semver from "semver"
import * as _ from "../../joy"

specifier = (name, qualifier = "latest") -> "#{name}@#{qualifier}"

fetchJSON = _.flow [ fetch, (response) -> response.json() ]

manifests = do (cache = {}) ->
  (name) ->
    cache[name] ?= await fetchJSON "https://registry.npmjs.org/#{name}"

resolve = (name, qualifier = "latest") ->
  p = await manifests name
  if qualifier == "latest"
    p["dist-tags"].latest
  else
    # the order of the manifests appears to be sorted by version already
    (Object.keys p.versions)
      .reverse()
      .find (v) -> semver.satisfies v, qualifier


manifest = do (cache = {}) ->
  (name, qualifier) ->
    cache[specifier name, qualifier] ?= await do ->
      v = await resolve name, qualifier
      fetchJSON "https://registry.npmjs.org/#{name}/#{v}"

export {
  specifier
  manifests
  resolve
  manifest
}
