import TreeIndex from "../categories/tree-index"
import ComponentGraph from "../categories/component-graph"
import Resolvers from "../resolvers"

formatPackageName = ( descriptor ) ->
  if descriptor.module.scope
    "#{descriptor.module.scope}/#{descriptor.module.name}"
  else
    descriptor.module.name

getComponentPackageName = ( context, component ) ->
  modules = ComponentGraph.getModules context.componentGraph, component
  module = ( Array.from modules )[ 0 ]
  descriptor = context.metaResolver.decode module
  formatPackageName descriptor

isRootComponent = ( treeIndex, component ) ->
  bindings = TreeIndex.getBindings treeIndex, []
  for [ label, target ] from bindings
    if target == component
      return label == component
  false

resolveRootDirectory = ( context, component ) ->
  if isRootComponent context.treeIndex, component
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
  if context.directoryCache.has key
    return context.directoryCache.get key
  directory = computeDirectory context, path, component
  context.directoryCache.set key, directory
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
  descriptor = context.metaResolver.decode url
  path = descriptor.path
  file = formatOutputFile directory, path
  context.bundle.set file, url
  return

processComponent = ( context, path, component ) ->
  directory = resolveDirectory context, path, component
  modules = ComponentGraph.getModules context.componentGraph, component
  for url from modules
    processModule context, directory, url
  return

processPath = ( context, path ) ->
  bindings = TreeIndex.getBindings context.treeIndex, path
  for component from bindings.values()
    processComponent context, path, component
  return

createContext = ( componentGraph, treeIndex, keys ) ->
  componentGraph: componentGraph
  treeIndex: treeIndex
  metaResolver: Resolvers.Registry.make keys
  bundle: new Map()
  directoryCache: new Map()

Resolver =
  apply: ( componentGraph, treeIndex, keys ) ->
    context = createContext componentGraph, treeIndex, keys
    paths = TreeIndex.getPaths treeIndex
    for path in paths
      processPath context, path
    context.bundle

export default Resolver