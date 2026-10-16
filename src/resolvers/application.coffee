import { pipe } from "@dashkite/joy"
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

  decode: pipe [
    AtlasURL.parse
    ( parsed ) ->
      resolver: parsed.resolver
      path: parsed.pathname
  ]

  parse: ( url ) ->
    @decode url

  resolve: pipe [
    ( url ) -> @decode url
    ( { path } ) -> normalizePath path
    ( path ) -> Path.resolve @root, path
    toFileURL
  ]

export default ApplicationResolver
export { ApplicationResolver }