import Resolvers from "../resolvers"

formatPackageName = ( descriptor ) ->
  if descriptor.module.scope
    "#{descriptor.module.scope}/#{descriptor.module.name}"
  else
    descriptor.module.name

getComponentPackageName = ( context, component ) ->
  modules = context.graph.getModules component
  module = ( Array.from modules )[ 0 ]
  descriptor = context.resolver.decode module
  formatPackageName descriptor

isRootComponent = ( index, component ) ->
  bindings = index.getBindings []
  for [ label, target ] from bindings
    if target == component
      return label == component
  false

resolveRootDirectory = ( context, component ) ->
  if isRootComponent context.index, component
    ""
  else
    name = getComponentPackageName context, component
    "node_modules/#{name}"

resolveParentDirectory = ( context, path ) ->
  component = path[ path.length - 1 ]
  path = path.slice 0, -1
  resolveDirectory context, path, component

formatNestedDirectory = ( directory, name ) ->
  if directory == ""
    "node_modules/#{name}"
  else
    "#{directory}/node_modules/#{name}"

resolveNestedDirectory = ( context, path, name ) ->
  directory = resolveParentDirectory context, path
  formatNestedDirectory directory, name

computeDirectory = ( context, path, component ) ->
  if path.length == 0
    resolveRootDirectory context, component
  else
    name = getComponentPackageName context, component
    resolveNestedDirectory context, path, name

resolveDirectory = ( context, path, component ) ->
  key = "#{component}::#{JSON.stringify path}"
  if context.cache.has key
    return context.cache.get key
  directory = computeDirectory context, path, component
  context.cache.set key, directory
  directory

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

processModule = ( context, directory, url ) ->
  descriptor = context.resolver.decode url
  path = descriptor.path
  file = formatOutputFile directory, path
  context.bundle.set file, url
  return

processComponent = ( context, path, component ) ->
  directory = resolveDirectory context, path, component
  modules = context.graph.getModules component
  for url from modules
    processModule context, directory, url
  return

processPath = ( context, path ) ->
  bindings = context.index.getBindings path
  for component from bindings.values()
    processComponent context, path, component
  return

createContext = ( graph, index, keys ) ->
  graph: graph
  index: index
  resolver: Resolvers.Registry.make keys
  bundle: new Map()
  cache: new Map()

Resolver =
  apply: ( graph, index, keys ) ->
    context = createContext graph, index, keys
    paths = index.getPaths()
    for path in paths
      processPath context, path
    context.bundle

export default Resolver