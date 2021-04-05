import F from "fs/promises"
import P from "path"
import { fileURLToPath as _fileURLToPath } from "url"
import fetch from "node-fetch"
import semver from "semver"
import * as _ from "@dashkite/joy"
import { error } from "./errors"

specifier = (name, qualifier = "latest") -> "#{name}@#{qualifier}"

fetchJSON = _.flow [ fetch, (response) -> response.json() ]

manifests = do (cache = {}) ->
  (name) ->
    cache[name] ?= await fetchJSON "https://registry.npmjs.org/#{name}"

resolve = (name, qualifier = "latest") ->
  if isURL qualifier
    (await manifest name, qualifier).version
  else
    p = await manifests name
    if qualifier == "latest"
      p["dist-tags"].latest
    else
      # the order of the manifests appears to be sorted by version already
      (Object.keys p.versions)
        .reverse()
        .find (v) -> semver.satisfies v, qualifier

isURL = (s) ->
  try
    new URL s
    true
  catch _e
    false

parseURL = (s) -> new URL s

# you've got to be kidding me...
fileURLToPath = (s) ->
  if s.startsWith "file:." then P.resolve s[5..]
  else _fileURLToPath s

manifest = do (cache = {}) ->
  (name, qualifier) ->
    cache[specifier name, qualifier] ?= await do ->
      if isURL qualifier
        url = parseURL qualifier
        switch url.protocol[...-1]
          when "http", "https" then fetch qualifier
          when "file"
            path = P.join (fileURLToPath qualifier), "package.json"
            JSON.parse await F.readFile path, "utf8"
          when "git" then throw error "git URL"
          else throw error "unsupported protocol", url.protocol[...-1]
      else
        v = await resolve name, qualifier
        fetchJSON "https://registry.npmjs.org/#{name}/#{v}"

export {
  specifier
  manifests
  resolve
  manifest
}
