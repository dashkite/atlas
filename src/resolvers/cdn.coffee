import AtlasURL from "../url"
import * as Codex from "@dashkite/url-codex"
import { isFunction } from "@dashkite/joy/type"

normalize = ( config ) ->
  if !config?.template?
    throw new Error "CDN resolver requires a URL Codex template string or
      function in configuration"
  { template } = config
  template: if isFunction template then template else -> template

# Convert string path to array for wildcard path expansion
segment = ( path ) ->
  ( path.split "/" ).filter Boolean

Format =
  tag: ( name, version ) ->
    if version then "#{name}@#{version}" else name

  specifier: ({ scope, name }) ->
    if scope then "#{scope}/#{name}" else name

  release: ( module ) ->
    Format.tag ( Format.specifier module ), module.version

  versioned: ({ name, version }) ->
    Format.tag name, version

  module: ( module ) ->
    {
      module...
      specifier: Format.specifier module
      release: Format.release module
      versioned: Format.versioned module
    }

Template =
  context: ( descriptor ) ->
    {
      ( Format.module descriptor.module )...
      path: segment descriptor.path
    }

  resolve: ( template, descriptor ) ->
    Codex.encode ( template descriptor ),
      Template.context descriptor

class CDNResolver
  @make: ( config ) ->
    Object.assign ( new @ ), normalize config

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