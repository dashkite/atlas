import Resolvers from "../resolvers"

formatPackageName = ( descriptor ) ->
  if descriptor.module.scope
    "#{descriptor.module.scope}/#{descriptor.module.name}"
  else
    descriptor.module.name

formatNestedDirectory = ( directory, name ) ->
  if directory == ""
    "node_modules/#{name}"
  else
    "#{directory}/node_modules/#{name}"

formatOutputFile = ( directory, path ) ->
  path =
    if path.startsWith "/"
      path.slice 1
    else
      path
  if directory == ""
    path
  else
    "#{directory}/#{path}"

class BundleResolver
  @make: ( graph, index, keys ) ->
    Object.assign ( new @ ),
      graph: graph
      index: index
      resolver: Resolvers.Registry.make keys
      bundle: new Map()
      cache: new Map()

  getComponentPackageName: ( component ) ->
    modules = @graph.getModules component
    module = ( Array.from modules )[ 0 ]
    descriptor = @resolver.decode module
    formatPackageName descriptor

  isRootComponent: ( component ) ->
    bindings = @index.getBindings []
    for [ label, target ] from bindings
      if target == component
        return label == component
    false

  resolveRootDirectory: ( component ) ->
    if @isRootComponent component
      ""
    else
      name = @getComponentPackageName component
      "node_modules/#{name}"

  resolveParentDirectory: ( path ) ->
    component = path[ path.length - 1 ]
    path = path.slice 0, -1
    @resolveDirectory path, component

  resolveNestedDirectory: ( path, name ) ->
    directory = @resolveParentDirectory path
    formatNestedDirectory directory, name

  computeDirectory: ( path, component ) ->
    if path.length == 0
      @resolveRootDirectory component
    else
      name = @getComponentPackageName component
      @resolveNestedDirectory path, name

  resolveDirectory: ( path, component ) ->
    key = "#{component}::#{JSON.stringify path}"
    if @cache.has key
      return @cache.get key
    directory = @computeDirectory path, component
    @cache.set key, directory
    directory

  processModule: ( directory, url ) ->
    descriptor = @resolver.decode url
    path = descriptor.path
    file = formatOutputFile directory, path
    @bundle.set file, url
    return

  processComponent: ( path, component ) ->
    directory = @resolveDirectory path, component
    modules = @graph.getModules component
    for url from modules
      @processModule directory, url
    return

  processPath: ( path ) ->
    bindings = @index.getBindings path
    for component from bindings.values()
      @processComponent path, component
    return

  resolve: ->
    for path in @index.getPaths()
      @processPath path
    @bundle

export default BundleResolver
export { BundleResolver }