import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"

match = ( context = {} ) ->
  if context.source.includes "node_modules"
    return false
  if context.source.startsWith ".."
    return false
  true

encode = ( descriptor ) ->
  AtlasURL.format { descriptor..., module: undefined }

decode = ( atlasUrl ) ->
  parsed = AtlasURL.parse atlasUrl
  {
    resolver: parsed.resolver
    path: parsed.pathname
  }

parse = ( atlasUrl ) ->
  @decode atlasUrl

normalizePath = ( path ) ->
  if path.startsWith "/"
    path.slice 1
  else
    path

resolvePath = ( config, path ) ->
  root = config.root ? config.cwd ? process.cwd()
  relativePath = normalizePath path
  Path.resolve root, relativePath

makeResolve = ( config ) ->
  ( atlasUrl ) ->
    descriptor = @decode atlasUrl
    absolutePath = resolvePath config, descriptor.path
    ( pathToFileURL absolutePath ).href

make = ( config = {} ) ->
  match: match
  encode: encode
  decode: decode
  parse: parse
  resolve: makeResolve config

export default { make }
export { make }