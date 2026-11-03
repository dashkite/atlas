import Ajv from "ajv"
import { pipe } from "@dashkite/joy"
import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"

ajv = new Ajv()

validateConfiguration = ajv.compile
  type: "object"
  properties:
    root:
      type: "string"
      minLength: 1

normalizePath = ( path ) ->
  if path.startsWith "/"
    path.slice 1
  else
    path

toFileURL = ( path ) ->
  ( pathToFileURL path ).href

class ApplicationResolver
  @make: ( configuration = {}) ->
    if validateConfiguration configuration
      Object.assign ( new @ ),
        root: configuration.root ? process.cwd()
    else
      throw new Error "Invalid Application resolver configuration"

  match: ( context ) ->
    { source } = context
    !( source.includes "node_modules" ) && !( source.startsWith ".." )

  encode: ( descriptor ) ->
    AtlasURL.encode { descriptor..., module: undefined }

  decode: ( url ) ->
    AtlasURL.decode url

  resolve: pipe [
    ( url ) -> @decode url
    ({ path }) -> normalizePath path
    ( path ) -> Path.resolve @root, path
    toFileURL
  ]

export default ApplicationResolver
export { ApplicationResolver }