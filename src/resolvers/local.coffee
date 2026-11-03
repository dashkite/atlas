import Ajv from "ajv"
import { pipe } from "@dashkite/joy"
import AtlasURL from "../url"
import Path from "node:path"
import micromatch from "micromatch"
import { pathToFileURL } from "node:url"

defaultPatterns = [ "../**/*", "packages/**/*" ]

ajv = new Ajv()

validateConfiguration = ajv.compile
  type: "object"
  required: [ "root" ]
  properties:
    root:
      type: "string"
      minLength: 1
    patterns:
      type: "array"
      items:
        type: "string"

normalize = ( configuration ) ->
  if validateConfiguration configuration
    root: configuration.root
    patterns: configuration.patterns ? defaultPatterns
  else
    throw new Error "Local resolver requires 'root' in configuration"

relative = ( path, directory ) ->
  if Path.isAbsolute path
    Path.relative directory, path
  else
    path

toFileURL = ( path ) ->
  ( pathToFileURL path ).href

class LocalResolver
  @make: ( configuration = {}) ->
    Object.assign ( new @ ), normalize configuration

  match: ( context ) ->
    { source } = context
    if !( source.includes "node_modules" ) && ( @patterns.length > 0 )
      path = relative source, ( context.cwd ? @root )
      micromatch.isMatch path, @patterns, { contains: true }
    else
      false

  encode: ( descriptor ) ->
    AtlasURL.encode descriptor

  decode: ( url ) ->
    AtlasURL.decode url

  resolve: pipe [
    ( url ) -> @decode url
    ({ path }) -> Path.resolve @root, path.slice 1
    toFileURL
  ]

export default LocalResolver
export { LocalResolver }