import AtlasURL from "../url"
import { encode as encodeTemplate } from "@dashkite/url-codex"
import { isFunction } from "@dashkite/joy/type"

normalizeConfig = ( config ) ->
  if !config?.template?
    throw new Error "CDN resolver requires a URL Codex template string or
      function in configuration"
  { template } = config
  template: if isFunction template then template else -> template

formatSpecifiers = ( module ) ->
  { scope, name, version } = module
  specifier = if scope then "#{scope}/#{name}" else name
  release = if version then "#{specifier}@#{version}" else specifier
  versioned = if version then "#{name}@#{version}" else name
  { module..., specifier, release, versioned }

resolveTemplate = ( template, descriptor ) ->
  data = formatSpecifiers descriptor.module
  # Convert string path to array for wildcard path expansion
  segments = ( descriptor.path.split "/" ).filter Boolean
  encodeTemplate ( template descriptor ),
    { data..., path: segments }

class CDNResolver
  @make: ( config ) ->
    Object.assign ( new @ ), normalizeConfig config

  match: ( context ) ->
    context.source.includes "node_modules"

  encode: ( descriptor ) ->
    AtlasURL.encode descriptor

  decode: ( url ) ->
    AtlasURL.decode url

  parse: ( url ) ->
    @decode url

  resolve: ( url ) ->
    resolveTemplate @template, @decode url

export default CDNResolver
export { CDNResolver }