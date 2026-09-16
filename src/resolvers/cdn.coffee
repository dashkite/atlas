import AtlasURL from "../url"
import { decode as urlDecode } from "@dashkite/url-codex"

scopedTemplate = "/{scope}/{versioned}/{path*}"
unscopedTemplate = "/{versioned}/{path*}"

encodeTemplate = ( templateString, data ) ->
  # Simple regex replacement for string templates
  templateString.replace /\{(\w+)(\*|\?)?\}/g, (match, key, modifier) ->
    val = data[key]
    if Array.isArray(val)
      val.join("/")
    else if val?
      val
    else
      ""

make = ( config = {} ) ->
  unless config.template?
    throw new Error "CDN resolver requires a URL Codex template string or function in configuration"
    
  match: ( context = {} ) ->
    return false unless typeof context.source == "string"
    return context.source.includes "node_modules"

  encode: ( descriptor ) ->
    AtlasURL.format descriptor
    
  decode: ( atlasUrl ) ->
    parsed = AtlasURL.parse atlasUrl
    
    res = try
      match = urlDecode scopedTemplate, parsed.pathname
      if match.scope?.startsWith("@") then match else throw new Error()
    catch
      urlDecode unscopedTemplate, parsed.pathname
      
    parts = res.versioned.split("@")
    name = parts[0]
    version = parts[1]
    
    {
      resolver: parsed.resolver
      module:
        scope: res.scope
        name: name
        version: version
      path: "/" + (res.path ? []).join("/")
    }

  parse: ( atlasUrl ) ->
    @decode atlasUrl

  resolve: ( atlasUrl ) ->
    descriptor = @decode atlasUrl
    
    specifier = if descriptor.module.scope
      "#{descriptor.module.scope}/#{descriptor.module.name}"
    else
      descriptor.module.name
      
    release = if descriptor.module.version
      "#{specifier}@#{descriptor.module.version}"
    else
      specifier
      
    versioned = if descriptor.module.version
      "#{descriptor.module.name}@#{descriptor.module.version}"
    else
      descriptor.module.name
      
    # Convert string path to array for wildcard path expansion
    pathSegments = (descriptor.path ? "").split("/").filter Boolean
      
    templateString = if typeof config.template == "function"
      config.template descriptor
    else
      config.template

    encodeTemplate templateString, {
      scope: descriptor.module.scope
      specifier
      release
      versioned
      path: pathSegments
    }

export default { make }
export { make }
