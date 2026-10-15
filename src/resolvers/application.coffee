import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"
import { pipe } from "@dashkite/joy"

match = ( context ) ->
  if context.source.includes "node_modules"
    return false
  if context.source.startsWith ".."
    return false
  true

encode = ( descriptor ) ->
  AtlasURL.format { descriptor..., module: undefined }

decode = ( url ) ->
  parsed = AtlasURL.parse url
  {
    resolver: parsed.resolver
    path: parsed.pathname
  }

parse = ( url ) ->
  @decode url

normalizePath = ( path ) ->
  if path.startsWith "/"
    path.slice 1
  else
    path

normalizeConfig = ( config ) ->
  root: config.root ? process.cwd()

resolvePath = ( config ) ->
  ( path ) ->
    Path.resolve config.root, normalizePath path

toFileURL = ( path ) ->
  ( pathToFileURL path ).href

decodePath = ( url ) ->
  ( decode url ).path

makeResolve = ( config ) ->
  pipe [
    decodePath
    resolvePath config
    toFileURL
  ]

make = ( config = {} ) ->
  match: match
  encode: encode
  decode: decode
  parse: parse
  resolve: makeResolve normalizeConfig config

export default { make }
export { make }