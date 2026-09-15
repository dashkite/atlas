import { URL } from "node:url"

AtlasURL =
  parse: ( urlString ) ->
    unless urlString.startsWith "atlas://"
      throw new TypeError "Invalid Protocol: URL must start with atlas://. Received: #{urlString}"
      
    parsed = new URL urlString
    resolverKey = if parsed.username then "#{decodeURIComponent(parsed.username)}@#{decodeURIComponent(parsed.hostname)}" else decodeURIComponent(parsed.hostname)
    
    {
      resolver: resolverKey
      pathname: parsed.pathname
    }

  format: ( descriptor ) ->
    unless descriptor.resolver?
      throw new TypeError "Cannot format Atlas URL without a resolver key"
      
    parts = descriptor.resolver.split "@"
    auth = if parts.length > 1
      "#{encodeURIComponent parts[0]}@#{encodeURIComponent parts.slice(1).join('@')}"
    else
      encodeURIComponent parts[0]
      
    pathSegments = []
    if descriptor.module?.name?
      pkgString = if descriptor.module.scope then "#{descriptor.module.scope}/#{descriptor.module.name}" else descriptor.module.name
      pkgString += "@#{descriptor.module.version}" if descriptor.module.version?
      pathSegments.push pkgString
      
    if descriptor.path? && descriptor.path != ""
      p = descriptor.path
      p = p.slice(1) if p.startsWith("/")
      pathSegments.push p if p != ""
      
    pathname = if pathSegments.length > 0
      "/" + pathSegments.join "/"
    else
      ""
      
    "atlas://#{auth}#{pathname}"

export default AtlasURL
export { AtlasURL }
