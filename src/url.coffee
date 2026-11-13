import { URL } from "node:url"
import { isString, isObject } from "@dashkite/joy/type"
import * as Codex from "@dashkite/url-codex"

Template =
  scoped: "/{scope}/{versioned}/{path*}"
  unscoped: "/{versioned}/{path*}"

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
    if module?
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
    if path?
      if path.startsWith "/"
        path.slice 1
      else
        path

  format: ( path = []) ->
    if path.length > 0 then "/#{path.join "/"}" else ""

Pathname =
  format: ({ module, path }) ->
    segments = [( Module.format module ), ( Path.normalize path )]
    Path.format segments.filter Boolean

  decode: ( pathname ) ->
    if pathname.startsWith "/@"
      Codex.decode Template.scoped, pathname
    else
      Codex.decode Template.unscoped, pathname

Descriptor =
  isValid: ( descriptor ) ->
    ( isObject descriptor ) &&
    ( isString descriptor.resolver ) &&
    ( descriptor.resolver.length > 0 )

decodePathname = ( resolver, pathname ) ->
  if resolver != "application"
    decoded = Pathname.decode pathname
    {
      resolver
      module: Module.parse decoded
      path: Path.format decoded.path
    }
  else
    { resolver, path: pathname }

encode = ( descriptor ) ->
  if Descriptor.isValid descriptor
    "atlas://#{formatAuthority descriptor.resolver}" +
      Pathname.format descriptor
  else
    throw new Error "Invalid AtlasURL descriptor"

decode = ( url ) ->
  if ( isString url ) && ( url.startsWith "atlas://" )
    parsed = new URL url
    resolver = extractResolver parsed
    if resolver.length > 0
      decodePathname resolver, parsed.pathname
    else
      throw new Error "Invalid AtlasURL authority: #{ url }"
  else
    throw new Error "Invalid AtlasURL: #{ url }"

export default { encode, decode }
export { encode, decode }
