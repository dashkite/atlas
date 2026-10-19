import { URL } from "node:url"
import { pipe } from "@dashkite/joy"
import * as Codex from "@dashkite/url-codex"

SCOPED_TEMPLATE = "/{scope}/{versioned}/{path*}"
UNSCOPED_TEMPLATE = "/{versioned}/{path*}"

extractResolver = ( parsed ) ->
  if parsed.username
    "#{decodeURIComponent parsed.username}@" +
      decodeURIComponent parsed.hostname
  else
    decodeURIComponent parsed.hostname

formatAuthority = ( resolver ) ->
  [ head, tail... ] = resolver.split "@"
  if tail.length > 0
    "#{encodeURIComponent head}@#{encodeURIComponent tail.join "@"}"
  else
    encodeURIComponent head

formatPackageSpecifier = ( module ) ->
  if module.scope
    "#{module.scope}/#{module.name}"
  else
    module.name

formatModuleIdentifier = ( module ) ->
  if !( module? )
    return
  specifier = formatPackageSpecifier module
  if module.version?
    "#{specifier}@#{module.version}"
  else
    specifier

normalizePath = ( path ) ->
  if !( path? )
    return
  if path.startsWith "/" then path.slice 1 else path

extractSegments = ( { module, path } ) ->
  [
    formatModuleIdentifier module
    normalizePath path
  ].filter Boolean

formatPathname = ( descriptor ) ->
  segments = extractSegments descriptor
  if segments.length > 0 then "/#{segments.join "/"}" else ""

decodePathname = ( pathname ) ->
  if pathname.startsWith "/@"
    Codex.decode SCOPED_TEMPLATE, pathname
  else
    Codex.decode UNSCOPED_TEMPLATE, pathname

parseModule = ( { scope, versioned } ) ->
  [ name, version ] = versioned.split "@"
  { scope, name, version }

formatDecodedPath = ( path = [] ) ->
  "/#{path.join "/"}"

buildDescriptor = ( resolver, decoded ) ->
  {
    resolver
    module: parseModule decoded
    path: formatDecodedPath decoded.path
  }

parse = ( url ) ->
  parsed = new URL url
  {
    resolver: extractResolver parsed
    pathname: parsed.pathname
  }

format = ( descriptor ) ->
  "atlas://#{formatAuthority descriptor.resolver}#{formatPathname descriptor}"

encode = ( descriptor ) ->
  format descriptor

decode = pipe [
  parse
  ( { resolver, pathname } ) ->
    buildDescriptor resolver, decodePathname pathname
]

export default { parse, format, encode, decode }
export { parse, format, encode, decode }