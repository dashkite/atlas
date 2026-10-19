import AtlasURL from "../url"

validate = (key, keys) ->
  if !( key in keys )
    throw new Error "Resolver #{key} not in configured keys"

lookup = (key) ->
  resolver = ResolverRegistry.get key
  if !resolver?
    throw new Error "Resolver #{key} not found in registry"
  resolver

extract = (url) ->
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

  get: (key) ->
    validate key, @keys
    lookup key

  locate: (url) ->
    @get extract url

  match: (context) ->
    for key in @keys
      resolver = lookup key
      if resolver.match context
        return key
    null

  encode: (descriptor) ->
    resolver = @get descriptor.resolver
    resolver.encode descriptor

  decode: (url) ->
    resolver = @locate url
    resolver.decode url

  parse: (url) ->
    @decode url

  resolve: (url) ->
    resolver = @locate url
    resolver.resolve url

export default ResolverRegistry
export { ResolverRegistry }