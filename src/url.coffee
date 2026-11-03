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

formatSpecifier = ( module ) ->
  if module.scope
    "#{module.scope}/#{module.name}"
  else
    module.name

Module =
  format: ( module ) ->
    if !( module? )
      return
    specifier = formatSpecifier module
    if module.version?
      "#{specifier}@#{module.version}"
    else
      specifier

  parse: ({ scope, versioned }) ->
    [ name, version ] = versioned.split "@"
    { scope, name, version }

Path =
  normalize: ( path ) ->
    if !( path? )
      return
    if path.startsWith "/" then path.slice 1 else path

  format: ( path = []) ->
    if path.length > 0 then "/#{path.join "/"}" else ""

extractSegments = ({ module, path }) ->
  [
    Module.format module
    Path.normalize path
  ].filter Boolean

Pathname =
  format: ( descriptor ) ->
    segments = extractSegments descriptor
    if segments.length > 0 then "/#{segments.join "/"}" else ""

  decode: ( pathname ) ->
    if pathname.startsWith "/@"
      Codex.decode SCOPED_TEMPLATE, pathname
    else
      Codex.decode UNSCOPED_TEMPLATE, pathname

buildDescriptor = ( resolver, decoded ) ->
  {
    resolver
    module: Module.parse decoded
    path: Path.format decoded.path
  }

decodePathname = ( resolver, pathname ) ->
  if resolver != "application"
    buildDescriptor resolver, Pathname.decode pathname
  else
    { resolver, path: pathname }

parseUrl = ( url ) ->
  parsed = new URL url
  {
    resolver: extractResolver parsed
    pathname: parsed.pathname
  }

encode = ( descriptor ) ->
  "atlas://#{formatAuthority descriptor.resolver}#{Pathname.format descriptor}"

decode = pipe [
  parseUrl
  ({ resolver, pathname }) ->
    decodePathname resolver, pathname
]

export default { encode, decode }
export { encode, decode }