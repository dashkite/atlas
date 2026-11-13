import AJV from "ajv"
import AtlasURL from "../url"
import * as Codex from "@dashkite/url-codex"
import { isFunction, isString } from "@dashkite/joy/type"

ajv = new AJV()

segment = ( path ) ->
  ( path.split "/" ).filter Boolean

formatModule = ( module ) ->
  { scope, name, version } = module
  specifier = if scope then "#{scope}/#{name}" else name
  release = if version then "#{specifier}@#{version}" else specifier
  versioned = if version then "#{name}@#{version}" else name
  { module..., specifier, release, versioned }

Template =
  isValid: ( template ) ->
    ( isFunction template ) ||
      (( isString template ) && ( template.length > 0 ))

  context: ( descriptor ) ->
    {
      ( formatModule descriptor.module )...
      path: segment descriptor.path
    }

  resolve: ( template, descriptor ) ->
    Codex.encode ( template descriptor ),
      Template.context descriptor

Configuration =
  validate: ajv.compile
    type: "object"
    required: [ "template" ]

  isValid: ( configuration ) ->
    ( Configuration.validate configuration ) &&
      ( Template.isValid configuration.template )

  normalize: ( configuration ) ->
    if Configuration.isValid configuration
      { template } = configuration
      template: if isFunction template then template else -> template
    else
      throw new Error (
        "CDN resolver requires a URL Codex template string or " +
        "function in configuration"
      )

class CDNResolver
  @make: ( configuration ) ->
    Object.assign ( new @ ), Configuration.normalize configuration

  match: ( context ) ->
    context.source.includes "node_modules"

  encode: ( descriptor ) ->
    AtlasURL.encode descriptor

  decode: ( url ) ->
    AtlasURL.decode url

  resolve: ( url ) ->
    Template.resolve @template, @decode url

export default CDNResolver
export { CDNResolver }