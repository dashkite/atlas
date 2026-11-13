import Resolvers from "../resolvers"

formatPackage = ({ module }) ->
  if module.scope
    "#{module.scope}/#{module.name}"
  else
    module.name

Directory =
  nest: ( directory, name ) ->
    if directory == ""
      "node_modules/#{name}"
    else
      "#{directory}/node_modules/#{name}"

  join: ( directory, path ) ->
    normalized = if path.startsWith "/" then path[ 1.. ] else path
    if directory == ""
      normalized
    else
      "#{directory}/#{normalized}"

class BundleResolver
  @make: ( graph, index, keys ) ->
    Object.assign ( new @ ),
      graph: graph
      index: index
      resolver: Resolvers.Registry.make keys
      directories: new Map()
      bundle: new Map()

  isRoot: ( component ) ->
    entry = ( Array.from @index.getBindings []).find ([ label, target ]) ->
      target == component
    if entry?
      entry[ 0 ] == component
    else
      false

  resolveName: ( component ) ->
    [ first ] = @graph.getModules component
    formatPackage @resolver.decode first

  computeDirectory: ( path, component ) ->
    if path.length == 0
      if @isRoot component
        ""
      else
        Directory.nest "", @resolveName component
    else
      parent = @resolveDirectory ( path.slice 0, -1 ), path.at -1
      Directory.nest parent, @resolveName component

  resolveDirectory: ( path, component ) ->
    key = "#{component}::#{JSON.stringify path}"
    if @directories.has key
      @directories.get key
    else
      directory = @computeDirectory path, component
      @directories.set key, directory
      directory

  add: ( directory, url ) ->
    { path } = @resolver.decode url
    @bundle.set ( Directory.join directory, path ), url
    return

  collect: ( path, component ) ->
    directory = @resolveDirectory path, component
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
