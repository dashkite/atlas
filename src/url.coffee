import { URL } from "node:url"

extractResolver = ( parsed ) ->
  if parsed.username
    "#{decodeURIComponent parsed.username}@" +
      decodeURIComponent parsed.hostname
  else
    decodeURIComponent parsed.hostname

formatAuthority = ( resolver ) ->
  parts = resolver.split "@"
  authority =
    if parts.length > 1
      "#{encodeURIComponent parts[ 0 ]}@" +
        encodeURIComponent ( parts.slice 1 ).join "@"
    else
      encodeURIComponent parts[ 0 ]
  authority

formatPackageSpecifier = ( module ) ->
  if module.scope
    "#{module.scope}/#{module.name}"
  else
    module.name

formatModuleIdentifier = ( module ) ->
  if !module?.name?
    return null
  specifier = formatPackageSpecifier module
  if module.version?
    "#{specifier}@#{module.version}"
  else
    specifier

normalizePath = ( path ) ->
  if ( !path? ) || ( path == "" )
    return null
  path = if path.startsWith "/" then path.slice 1 else path
  if path != "" then path else null

formatPathname = ( descriptor ) ->
  segments = []
  identifier = formatModuleIdentifier descriptor.module
  segments.push identifier if identifier?
  path = normalizePath descriptor.path
  segments.push path if path?
  if segments.length > 0 then "/" + segments.join "/" else ""

export default
  parse: ( url ) ->
    parsed = new URL url
    {
      resolver: extractResolver parsed
      pathname: parsed.pathname
    }

  format: ( descriptor ) ->
    "atlas://#{formatAuthority descriptor.resolver}#{formatPathname descriptor}"