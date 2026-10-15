import AtlasURL from "../url"
import { decode as urlDecode } from "@dashkite/url-codex"
import { isFunction } from "@dashkite/joy/type"

SCOPED_TEMPLATE = "/{scope}/{versioned}/{path*}"
UNSCOPED_TEMPLATE = "/{versioned}/{path*}"

encodeTemplate = ( template, data ) ->
  # Simple regex replacement for string templates
  template.replace /\{(\w+)(\*|\?)?\}/g, (match, key, modifier) ->
    value = data[key]
    if modifier == "*"
      value.join "/"
    else if value?
      value
    else
      ""

normalizeConfig = ( config ) ->
  if !config?.template?
    throw new Error "CDN resolver requires a URL Codex template string or
      function in configuration"
  { template } = config
  template: if isFunction template then template else -> template

decodeTemplate = ( pathname ) ->
  try
    match = urlDecode SCOPED_TEMPLATE, pathname
    if match.scope.startsWith "@" then match else throw new Error
  catch
    urlDecode UNSCOPED_TEMPLATE, pathname

parseModuleDescriptor = ( parsed, match ) ->
  parts = match.versioned.split "@"
  resolver: parsed.resolver
  module:
    scope: match.scope
    name: parts[0]
    version: parts[1]
  path: "/" + match.path.join "/"

formatSpecifiers = ( module ) ->
  { scope, name, version } = module
  specifier = if scope then "#{scope}/#{name}" else name
  release = if version then "#{specifier}@#{version}" else specifier
  versioned = if version then "#{name}@#{version}" else name
  { scope, specifier, release, versioned }

resolveTemplate = ( template, descriptor, data ) ->
  # Convert string path to array for wildcard path expansion
  segments = ( descriptor.path.split "/" ).filter Boolean
  encodeTemplate ( template descriptor ),
    Object.assign {}, data, path: segments

class CDNResolver
  @make: ( config ) ->
    Object.assign ( new @ ), normalizeConfig config

  match: ( context ) ->
    context.source.includes "node_modules"

  encode: ( descriptor ) ->
    AtlasURL.format descriptor

  decode: ( url ) ->
    parsed = AtlasURL.parse url
    match = decodeTemplate parsed.pathname
    parseModuleDescriptor parsed, match

  parse: ( url ) ->
    @decode url

  resolve: ( url ) ->
    descriptor = @decode url
    data = formatSpecifiers descriptor.module
    resolveTemplate @template, descriptor, data

export default CDNResolver
export { CDNResolver }