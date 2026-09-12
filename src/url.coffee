import { URL } from "node:url"

AtlasURL =
  parse: ( urlString ) ->
    unless urlString.startsWith "atlas://"
      throw new TypeError "Invalid Protocol: URL must start with atlas://. Received: #{urlString}"
      
    parsed = new URL urlString
    type = parsed.hostname
    segments = parsed.pathname.split("/").filter Boolean
    
    if type == "application" || type == "app" || type == "cdn" || type == "virtual-root"
      return {
        type
        subpath: segments.join "/"
      }
      
    if type == "npm" || type == "local"
      if segments.length == 0
        throw new TypeError "Invalid Atlas URL: #{type} requires a package specifier."
        
      if segments[0].startsWith "@"
        if segments.length < 2
          throw new TypeError "Invalid Atlas URL: scoped package missing name in #{urlString}"
        specifier = "#{segments[0]}/#{segments[1]}"
        subpath = segments.slice(2).join "/"
      else
        specifier = segments[0]
        subpath = segments.slice(1).join "/"
        
      if specifier.startsWith "@"
        parts = specifier.split "@"
        pkgName = "@" + parts[1]
        version = parts[2]
      else
        parts = specifier.split "@"
        pkgName = parts[0]
        version = parts[1]
        
      return {
        type
        specifier
        package: pkgName
        version: version
        subpath
      }
      
    throw new TypeError "Unknown resolver type: #{type}"

  format: ( { type, specifier, subpath } ) ->
    unless type?
      throw new TypeError "Cannot format Atlas URL without a type"
      
    pathSegments = []
    pathSegments.push specifier if specifier? && specifier != ""
    pathSegments.push subpath if subpath? && subpath != ""
    
    pathname = if pathSegments.length > 0
      "/" + pathSegments.join "/"
    else
      ""
      
    "atlas://#{type}#{pathname}"

export default AtlasURL
export { AtlasURL }
