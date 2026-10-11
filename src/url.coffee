import { URL } from "node:url"

extractResolver = ( parsed ) ->
  if parsed.username
    "#{decodeURIComponent parsed.username}@#{decodeURIComponent parsed.hostname}"
  else
    decodeURIComponent parsed.hostname

formatAuthority = ( resolver ) ->
  parts = resolver.split "@"
  authority = if parts.length > 1
    "#{encodeURIComponent parts[ 0 ]}@#{encodeURIComponent ( parts.slice 1 ).join "@"}"
  else
    encodeURIComponent parts[ 0 ]
  authority

formatModuleIdentifier = ( module ) ->
  if !module?.name?
    return null
  packageSpecifier = if module.scope then "#{module.scope}/#{module.name}" else module.name
  if module.version? then "#{packageSpecifier}@#{module.version}" else packageSpecifier

normalizePath = ( path ) ->
  if !path? || path == ""
    return null
  normalizedPath = if path.startsWith "/" then path.slice 1 else path
  if normalizedPath != "" then normalizedPath else null

formatPathname = ( descriptor ) ->
  pathSegments = []
  moduleIdentifier = formatModuleIdentifier descriptor.module
  pathSegments.push moduleIdentifier if moduleIdentifier?
  normalizedPath = normalizePath descriptor.path
  pathSegments.push normalizedPath if normalizedPath?
  if pathSegments.length > 0 then "/" + pathSegments.join "/" else ""

AtlasURL =
  parse: ( url ) ->
    parsed = new URL url
    {
      resolver: extractResolver parsed
      pathname: parsed.pathname
    }

  format: ( descriptor ) ->
    authority = formatAuthority descriptor.resolver
    pathname = formatPathname descriptor
    "atlas://#{authority}#{pathname}"

export default AtlasURL
export { AtlasURL }