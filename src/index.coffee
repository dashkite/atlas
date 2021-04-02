import F from "fs/promises"
import pacote from "pacote"
import semver from "semver"
import * as _ from "../../joy"
import * as R from "panda-river"

log = _.tee (context) -> console.log context

assoc = (px) ->
  r = {}
  for [key, value] in px
    r[key] = value
  r

manifest = do (cache = {}) ->
  (name, spec) ->
    spec ?= "latest"
    cache[name] ?= await pacote.manifest "#{name}@#{spec}",
      fullMetadata: true

dependencies = _.flow [
  manifest
  _.get "dependencies"
  (dx) -> if dx? then px = _.pairs dx else []
  (px) ->
    zx = for [name, spec] in px
      dependencies name, spec
    _.merge {}, (assoc px), (await Promise.all zx)...
  ]

lock = (dx) ->
  rx = {}
  for name, spec of dx
    p = await manifest name, spec
    rx[name] = p.version
  rx

scope = (dx) ->
  rx = {}
  for name, version of dx
    p = await manifest name, version
    rx[name] = "https://ga.jspm.io/npm:
      #{name}@#{version}/#{p.main ? 'index.js'}"
  rx

imports = _.flow [
  lock
  scope
]

scoped = _.flow [
  (dx) -> (dependencies name, spec) for name, spec of dx
  (dx) -> Promise.all dx
  (dx) -> _.merge dx...
  imports
]


generate = (dx) ->
  imports: await imports dx
  scopes:
    "https://ga.jspm.io/": await scoped dx

do ->
  console.log await generate
    "@dashkite/carbon": undefined
