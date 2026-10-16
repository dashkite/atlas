import { URL } from "node:url"

extractResolver = ( parsed ) ->
  if parsed.username
    "#{decodeURIComponent parsed.username}@" +
      decodeURIComponent parsed.hostname
  else
    decodeURIComponent parsed.hostname

formatAuthority = ( resolver ) ->
  [ head, tail... ] = resolver.split "@"
  if tail.length > 0
    "#{encodeURIComponent head}@#{encodeURIComponent tail.join '@'}"
  else
    encodeURIComponent head

formatPackageSpecifier = ( module ) ->
  if module.scope
    "#{module.scope}/#{module.name}"
  else
    module.name

formatModuleIdentifier = ( module ) ->
  return unless module?
  specifier = formatPackageSpecifier module
  if module.version?
    "#{specifier}@#{module.version}"
  else
    specifier

normalizePath = ( path ) ->
  return unless path?
  if path.startsWith "/" then path.slice 1 else path

extractSegments = ( { module, path } ) ->
  [
    formatModuleIdentifier module
    normalizePath path
  ].filter Boolean

formatPathname = ( descriptor ) ->
  segments = extractSegments descriptor
  if segments.length > 0 then "/#{segments.join '/'}" else ""

export default
  parse: ( url ) ->
    parsed = new URL url
    {
      resolver: extractResolver parsed
      pathname: parsed.pathname
    }

  format: ( descriptor ) ->
    "atlas://#{formatAuthority descriptor.resolver}#{formatPathname descriptor}"