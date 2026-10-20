import AtlasURL from "../url"
import { encode as encodeTemplate } from "@dashkite/url-codex"
import { isFunction } from "@dashkite/joy/type"

normalizeConfig = ( config ) ->
  if !config?.template?
    throw new Error "CDN resolver requires a URL Codex template string or
      function in configuration"
  { template } = config
  template: if isFunction template then template else -> template

appendVersion = ( name, version ) ->
  if version then "#{name}@#{version}" else name

formatSpecifier = ({ scope, name }) ->
  if scope then "#{scope}/#{name}" else name

formatRelease = ( module ) ->
  appendVersion ( formatSpecifier module ), module.version

formatVersioned = ({ name, version }) ->
  appendVersion name, version

formatSpecifiers = ( module ) ->
  {
    module...
    specifier: formatSpecifier module
    release: formatRelease module
    versioned: formatVersioned module
  }

# Convert string path to array for wildcard path expansion
segmentPath = ( path ) ->
  ( path.split "/" ).filter Boolean

buildTemplateContext = ( descriptor ) ->
  {
    ( formatSpecifiers descriptor.module )...
    path: segmentPath descriptor.path
  }

resolveTemplate = ( template, descriptor ) ->
  encodeTemplate ( template descriptor ),
    buildTemplateContext descriptor

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