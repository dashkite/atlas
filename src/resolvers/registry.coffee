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
    unless descriptor.resolver in @keys
      throw new Error "Resolver #{descriptor.resolver} not in configured keys"
    resolver = Registry.get descriptor.resolver
    unless resolver?
      throw new Error "Resolver #{descriptor.resolver} not found in registry"
    resolver.encode descriptor
    
  decode: (atlasUrl) ->
    parsed = AtlasURL.parse atlasUrl
    key = parsed.resolver
    unless key in @keys
      throw new Error "Resolver #{key} not in configured keys"
    resolver = Registry.get key
    unless resolver?
      throw new Error "Resolver #{key} not found in registry"
    resolver.decode atlasUrl

  parse: (atlasUrl) ->
    @decode atlasUrl

  resolve: (atlasUrl) ->
    parsed = AtlasURL.parse atlasUrl
    key = parsed.resolver
    unless key in @keys
      throw new Error "Resolver #{key} not in configured keys"
    resolver = Registry.get key
    unless resolver?
      throw new Error "Resolver #{key} not found in registry"
    resolver.resolve atlasUrl

class Registry
  @resolvers: {}

  @register: (key, resolver) ->
    @resolvers[key] = resolver

  @get: (key) ->
    @resolvers[key]

  @make: (keys) ->
    new MetaResolver keys

export default Registry
