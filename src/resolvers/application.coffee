import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"

normalizePath = ( path ) ->
  if path.startsWith "/"
    path.slice 1
  else
    path

toFileURL = ( path ) ->
  ( pathToFileURL path ).href

class ApplicationResolver
  @make: ( config = {} ) ->
    Object.assign ( new @ ),
      root: config.root ? process.cwd()

  match: ( context ) ->
    if context.source.includes "node_modules"
      return false
    if context.source.startsWith ".."
      return false
    true

  encode: ( descriptor ) ->
    AtlasURL.format { descriptor..., module: undefined }

  decode: ( url ) ->
    parsed = AtlasURL.parse url
    {
      resolver: parsed.resolver
      path: parsed.pathname
    }

  parse: ( url ) ->
    @decode url

  resolve: ( url ) ->
    { path } = @decode url
    resolved = Path.resolve @root, normalizePath path
    toFileURL resolved

export default ApplicationResolver
export { ApplicationResolver }