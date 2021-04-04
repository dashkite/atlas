import F from "fs/promises"
import P from "path"
import fetch from "node-fetch"
import * as m from "@dashkite/mercury"
import semver from "semver"
import * as _ from "../../joy"
import * as R from "panda-river"

# _scope = "https://cdn.jsdelivr.net/npm/"
_scope = "https://ga.jspm.io/npm:"

log = _.tee (context) -> console.log context

client = ({url, method, headers, body}) ->
  fetch url, {method: (method.toUpperCase()), headers, body,  mode: "cors" }

describe = do (cache = {}) ->
  (name) ->
    cache[name] ?= await do _.flow [
      m.use client
      m.method "get"
      m.url "https://registry.npmjs.org/#{name}"
      m.request
      m.json
      _.get "json"
    ]

assoc = (px) ->
  r = {}
  for [key, value] in px
    r[key] = value
  r

resolve = (name, qualifier = "latest") ->
  p = await describe name
  if qualifier == "latest"
    p["dist-tags"].latest
  else
    # console.log Object.keys p.versions
    (Object.keys p.versions)
      .reverse()
      .find (v) -> semver.satisfies v, qualifier

specifier = (name, qualifier = "latest") -> "#{name}@#{qualifier}"

manifest = do (cache = {}) ->
  (name, qualifier) ->
    cache[specifier name, qualifier] ?= await do ->
      v = await resolve name, qualifier
      do _.flow [
        m.use client
        m.method "get"
        m.url "https://registry.npmjs.org/#{name}/#{v}"
        m.request
        m.json
        _.get "json"
      ]

dependencies = (name, qualifier, rx = {}) ->
  console.log specifier name, qualifier
  _manifest = await manifest name, qualifier
  rx[specifier name, _manifest.version] ?=
    for _name, _qualifier of _manifest.dependencies
      await dependencies _name, _qualifier, rx
      name: _name
      qualifier: _qualifier
      version: await resolve _name, _qualifier
  rx

eq = (a, b) -> a.name == b.name && a.version == b.version

compatible = (a, b) ->
  (a.name == b.name) &&
    (semver.validRange a.qualifier)? && (semver.validRange b.qualifier)? &&
      (semver.satisfies a.version, b.qualifier) &&
        (semver.satisfies b.version, a.qualifier)

req = (a, b) -> (eq a, b) || (compatible a, b)
found = (dx, d) -> dx.find eq
alternate = (dx, b) -> dx.find (a) -> req a, b
conflict = (dx, b) -> (dx.find (a) -> a.name == b.name && !(req a, b))?
available = (dx, b) -> !conflict dx, b
promote = (a, b) -> if semver.gt a.version, b.version then a else b

place = (dx, d) ->
  !!(
    if (available dx, d)
      if (_d = alternate dx, d)?
        dx.push promote d, _d
      else
        dx.push d
  )

parent = (s) ->
  x = s.split "@"
  x[x.length - 2]

optimize = (sx) ->
  counts = {}
  rx = root: []
  for s, dx of sx
    rx[s] = []
    rx[parent s] = []
    for d in dx
      counts[specifier d.name, d.version] ?= 0
      counts[specifier d.name, d.version]++
      if (found rx.root, d) || (found rx[parent s], d)
        continue
      else if !(place rx.root, d) && !(place rx[parent s], d)
        rx[s].push d
  console.log counts
  rx

unique = (f, ax) ->
  bx = []
  for a in ax
    if !(bx.find (b) -> f a, b)?
      bx.push a
  bx

compact = (sx) ->
  rx = {}
  for key, value of sx when !_.empty value
    rx[key] = unique eq, value
  rx

# lock = (dx) ->
#   rx = {}
#   for name, spec of dx
#     p = await manifest name, spec
#     rx[name] = p.version
#   rx
#
# subpaths = (p) ->
#   if p.exports?
#     if _.isString p.exports
#       [p.name]: p.exports
#     else
#       console.warn "#{p.name}: export subpaths are not yet supported"
#       {}
#   else
#     [p.name]: p.module ? p.main ? "index.js"
#
#
# pathToURL = (base, path) -> "#{base}/#{path}"
#
# pathsToURLs = (base, dx) ->
#   rx = {}
#   for name, path of dx
#     rx[name] = pathToURL base, path
#   rx
#
# scope = (dx) ->
#   rx = {}
#   for name, version of dx
#     u = "#{_scope}#{name}@#{version}"
#     p = await manifest name, version
#     _.assign rx, pathsToURLs u, subpaths p
#   rx
#
# imports = _.flow [
#   lock
#   scope
# ]
#
# expand = _.flow [
#   (dx) -> (dependencies name, spec) for name, spec of dx
#   (dx) -> Promise.all dx
#   (dx) -> _.merge dx...
#   imports
# ]
#
# generate = (dx) ->
#   imports: await imports dx
#   scopes:
#     [(new URL _scope).origin]: await expand dx

do ->
  # console.log JSON.stringify await generate
  #   "@dashkite/carbon": undefined
  #   "@dashkite/quark": undefined
  #   # "@dashkite/joy": "file:../joy"

  # TODO we need to add the root dependencies somehow at the start
  # TODO we could keep a count of how many times we see a module,
  #      so we could prioritize which one gets the root
  # TODO i'd like to get rid of the myriad side-effects in this impl.
  console.log compact optimize await dependencies "@dashkite/carbon"
