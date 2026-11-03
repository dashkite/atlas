import Ajv from "ajv"
import AtlasURL from "../url"
import * as Codex from "@dashkite/url-codex"
import { isFunction, isString } from "@dashkite/joy/type"

ajv = new Ajv()

segment = ( path ) ->
  ( path.split "/" ).filter Boolean

Format =
  tag: ( name, version ) ->
    if version then "#{name}@#{version}" else name

  specifier: ({ scope, name }) ->
    if scope then "#{scope}/#{name}" else name

  release: ( module ) ->
    Format.tag ( Format.specifier module ), module.version

  module: ( module ) ->
    {
      module...
      specifier: Format.specifier module
      release: Format.release module
      versioned: Format.tag module.name, module.version
    }

Template =
  isValid: ( template ) ->
    ( isFunction template ) ||
      (( isString template ) && ( template.length > 0 ))

  context: ( descriptor ) ->
    {
      ( Format.module descriptor.module )...
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