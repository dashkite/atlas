import AJV from "ajv"
import { isString, isObject, isBoolean, isKind } from "@dashkite/joy/type"
import AtlasURL from "../url"

ajv = new AJV()

validateKeys = ajv.compile
  type: "array"
  minItems: 1
  items:
    type: "string"
    minLength: 1

validate = ( key, keys ) ->
  if key in keys
    key
  else
    throw new Error "Resolver #{key} not in configured keys"

lookup = ( key ) ->
  resolver = ResolverRegistry.get key
  if resolver?
    resolver
  else
    throw new Error "Resolver #{key} not found in registry"

checkKey = ( key ) ->
  ( isString key ) && ( key.length > 0 )

checkURL = ( url ) ->
  ( isString url ) && ( url.startsWith "atlas://" )

checkResolver = ( resolver ) ->
  ( isObject resolver ) || ( isKind Object, resolver )

matchesContext = ( context ) ->
  ( key ) ->
    resolver = lookup key
    result = resolver.match context
    if isBoolean result
      result
    else
      throw new Error "Resolver #{key} match must return a boolean"

class ResolverRegistry
  @resolvers: {}

  @register: ( key, resolver ) ->
    if ( checkKey key ) && ( checkResolver resolver )
      existing = @resolvers[ key ]
      @resolvers[ key ] =
        if existing?
          Object.assign ( Object.create existing ), resolver
        else
          resolver
    else
      throw new Error "Resolver registration requires a non-empty key and " +
        "resolver object"

  @get: ( key ) ->
    if checkKey key
      @resolvers[ key ]
    else
      throw new Error "Resolver key must be a non-empty string"

  @make: ( keys ) ->
    if validateKeys keys
      Object.assign ( new @ ), { keys }
    else
      throw new Error "Resolver keys must be a non-empty array of strings"

  get: ( key ) ->
    lookup validate key, @keys

  locate: ( url ) ->
    { resolver } = AtlasURL.decode url
    @get resolver

  match: ( context ) ->
    if ( isObject context ) && ( checkKey context.source )
      matched = @keys.find matchesContext context
      matched ? null
    else
      throw new Error "Match context requires a non-empty source string"

  encode: ( descriptor ) ->
    if ( isObject descriptor ) && ( checkKey descriptor.resolver )
      url = ( @get descriptor.resolver ).encode descriptor
      if checkURL url
        url
      else
        throw new Error "Resolver #{descriptor.resolver} encode must " +
          "return an atlas:// URL"
    else
      throw new Error "Dependency descriptor requires a non-empty resolver key"

  decode: ( url ) ->
    if checkURL url
      descriptor = ( @locate url ).decode url
      if ( isObject descriptor ) && ( checkKey descriptor.resolver )
        descriptor
      else
        AtlasURL.decode url
    else
      throw new Error "Expected an atlas:// URL to decode"

  resolve: ( url ) ->
    if checkURL url
      resolved = ( @locate url ).resolve url
      if checkKey resolved
        resolved
      else
        throw new Error "Resolver resolve must return a non-empty URL string"
    else
      throw new Error "Expected an atlas:// URL to resolve"

export default ResolverRegistry
export { ResolverRegistry }