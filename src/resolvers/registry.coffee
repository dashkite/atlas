import AtlasURL from "../url"

validateKey = (key, keys) ->
  if !( key in keys )
    throw new Error "Resolver #{key} not in configured keys"

lookupResolver = (key) ->
  resolver = ResolverRegistry.get key
  if !resolver?
    throw new Error "Resolver #{key} not found in registry"
  resolver

extractKey = (url) ->
  parsed = AtlasURL.parse url
  parsed.resolver

class ResolverRegistry
  @resolvers: {}

  @register: (key, resolver) ->
    @resolvers[key] = resolver

  @get: (key) ->
    @resolvers[key]

  @make: (keys) ->
    Object.assign ( new @ ), { keys }

  getResolver: (key) ->
    validateKey key, @keys
    lookupResolver key

  getResolverForUrl: (url) ->
    @getResolver extractKey url

  match: (context) ->
    for key in @keys
      resolver = lookupResolver key
      if resolver.match context
        return key
    null

  encode: (descriptor) ->
    resolver = @getResolver descriptor.resolver
    resolver.encode descriptor

  decode: (url) ->
    resolver = @getResolverForUrl url
    resolver.decode url

  parse: (url) ->
    @decode url

  resolve: (url) ->
    resolver = @getResolverForUrl url
    resolver.resolve url

export default ResolverRegistry
export { ResolverRegistry }