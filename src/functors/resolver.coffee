import { pipe } from "@dashkite/joy"
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

  getComponentPackageName: pipe [
    ( component ) -> @graph.getModules component
    ( modules ) -> ( Array.from modules )[ 0 ]
    ( module ) -> @resolver.decode module
    formatPackageName
  ]

  isRootComponent: ( component ) ->
    for [ label, target ] from @index.getBindings []
      if target == component
        return label == component
    false

  resolveRootDirectory: ( component ) ->
    if @isRootComponent component
      ""
    else
      "node_modules/#{@getComponentPackageName component}"

  resolveParentDirectory: ( path ) ->
    @resolveDirectory ( path.slice 0, -1 ), path[ path.length - 1 ]

  resolveNestedDirectory: ( path, name ) ->
    formatNestedDirectory ( @resolveParentDirectory path ), name

  computeDirectory: ( path, component ) ->
    if path.length == 0
      @resolveRootDirectory component
    else
      @resolveNestedDirectory path, @getComponentPackageName component

  resolveDirectory: ( path, component ) ->
    key = "#{component}::#{JSON.stringify path}"
    if @cache.has key
      return @cache.get key
    directory = @computeDirectory path, component
    @cache.set key, directory
    directory

  processModule: ( directory, url ) ->
    { path } = @resolver.decode url
    @bundle.set ( formatOutputFile directory, path ), url
    return

  processComponent: ( path, component ) ->
    directory = @resolveDirectory path, component
    for url from @graph.getModules component
      @processModule directory, url
    return

  processPath: ( path ) ->
    for component from ( @index.getBindings path ).values()
      @processComponent path, component
    return

  resolve: ->
    for path in @index.getPaths()
      @processPath path
    @bundle

functor = ( graph, index, keys ) ->
  ( BundleResolver.make graph, index, keys ).resolve()

export default functor
export { BundleResolver }