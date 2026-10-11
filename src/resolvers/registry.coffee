import AtlasURL from "../url"

class MetaResolver
  constructor: (@keys) ->

  match: (context) ->
    for key in @keys
      resolver = Registry.get key
      if resolver?.match context
        return key
    null

  encode: (descriptor) ->
    if !descriptor.resolver in @keys
      throw new Error "Resolver #{descriptor.resolver} not in configured keys"
    resolver = Registry.get descriptor.resolver
    if !resolver?
      throw new Error "Resolver #{descriptor.resolver} not found in registry"
    resolver.encode descriptor

  decode: (url) ->
    parsed = AtlasURL.parse url
    key = parsed.resolver
    if !key in @keys
      throw new Error "Resolver #{key} not in configured keys"
    resolver = Registry.get key
    if !resolver?
      throw new Error "Resolver #{key} not found in registry"
    resolver.decode url

  parse: (url) ->
    @decode url

  resolve: (url) ->
    parsed = AtlasURL.parse url
    key = parsed.resolver
    if !key in @keys
      throw new Error "Resolver #{key} not in configured keys"
    resolver = Registry.get key
    if !resolver?
      throw new Error "Resolver #{key} not found in registry"
    resolver.resolve url

class Registry
  @register: (key, resolver) ->
    @resolvers[key] = resolver

  @get: (key) ->
    @resolvers[key]

  @make: (keys) ->
    new MetaResolver keys

Registry.resolvers = {}

export default Registry