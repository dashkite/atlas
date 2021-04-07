import { scopes } from "./scopes"
import { specifier } from "./manifest"
import { error } from "./errors"
import * as _ from "@dashkite/joy"

join = (args...) -> args.join "/"

scopeToURL = (s) -> join "https://cdn.jsdelivr.net/npm/", s

fullURL = ({name, version, qualifier, entry}) ->
  base = scopeToURL specifier name, version
  join base, entry

subpaths = ({name, version, manifest}) ->
  if _.isString manifest.exports
    [name]: fullURL {name, version, entry: manifest.exports}
  else
    if (entry = manifest.exports["."])?
      [name]: fullURL {name, version, entry}
    else
      throw error "exports conditions", specifier name, version


expand = ({name, version, manifest}) ->
  if manifest.exports?
    subpaths {name, version, manifest}
  else
    if (entry = (manifest.module ? manifest.browser))?
      [name]: fullURL {name, version, entry}
    else
      throw error "no exports", specifier name, version


_map = (dx) ->
  rx = {}
  for d in dx
    rx = {rx..., (expand d)...}
  rx

map = (dx) ->
  sx = await scopes dx
  rx = {}
  for s, dx of sx
    if s == "root"
      rx.imports = _map dx
    else
      (rx.scopes ?= {})[scopeToURL s] = _map dx
  rx

export { map }
