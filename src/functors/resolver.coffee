import { pipe } from "@dashkite/joy"
import Resolvers from "../resolvers"

Package =
  format: ( descriptor ) ->
    if descriptor.module.scope
      "#{descriptor.module.scope}/#{descriptor.module.name}"
    else
      descriptor.module.name

class PackageComponent
  @make: ( graph, index, resolver ) ->
    Object.assign ( new @ ),
      graph: graph
      index: index
      resolver: resolver

  name: pipe [
    ( component ) -> @graph.getModules component
    ( modules ) -> ( Array.from modules )[ 0 ]
    ( module ) -> @resolver.decode module
    Package.format
  ]

  isRoot: ( component ) ->
    for [ label, target ] from @index.getBindings []
      if target == component
        return label == component
    false

class BundleDirectory
  @nest: ( directory, name ) ->
    if directory == ""
      "node_modules/#{name}"
    else
      "#{directory}/node_modules/#{name}"

  @join: ( directory, path ) ->
    path =
      if path.startsWith "/"
        path.slice 1
      else
        path
    if directory == ""
      path
    else
      "#{directory}/#{path}"

  @make: ( component ) ->
    Object.assign ( new @ ),
      component: component
      cache: new Map()

  root: ( component ) ->
    if @component.isRoot component
      ""
    else
      "node_modules/#{@component.name component}"

  parent: ( path ) ->
    @resolve ( path.slice 0, -1 ), path[ path.length - 1 ]

  nested: ( path, name ) ->
    BundleDirectory.nest ( @parent path ), name

  compute: ( path, component ) ->
    if path.length == 0
      @root component
    else
      @nested path, @component.name component

  resolve: ( path, component ) ->
    key = "#{component}::#{JSON.stringify path}"
    if @cache.has key
      return @cache.get key
    directory = @compute path, component
    @cache.set key, directory
    directory

class BundleResolver
  @make: ( graph, index, keys ) ->
    resolver = Resolvers.Registry.make keys
    component = PackageComponent.make graph, index, resolver
    Object.assign ( new @ ),
      graph: graph
      index: index
      resolver: resolver
      directory: BundleDirectory.make component
      bundle: new Map()

  add: ( directory, url ) ->
    { path } = @resolver.decode url
    @bundle.set ( BundleDirectory.join directory, path ), url
    return

  collect: ( path, component ) ->
    directory = @directory.resolve path, component
    for url from @graph.getModules component
      @add directory, url
    return

  visit: ( path ) ->
    for component from ( @index.getBindings path ).values()
      @collect path, component
    return

  resolve: ->
    for path in @index.getPaths()
      @visit path
    @bundle

functor = ( graph, index, keys ) ->
  ( BundleResolver.make graph, index, keys ).resolve()

export default functor
export { BundleResolver }