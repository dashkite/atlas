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
  firstModule = ( Array.from modules )[ 0 ]
  descriptor = context.metaResolver.decode firstModule
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
    packageName = getComponentPackageName context, component
    "node_modules/#{packageName}"

validatePackageName = ( component, packageName ) ->
  if packageName == ""
    throw new Error "Nested dependency [#{component}] is missing a
      package specifier."

resolveParentDirectory = ( context, path ) ->
  parentComponent = path[ path.length - 1 ]
  parentPath = path.slice 0, -1
  resolveDirectory context, parentPath, parentComponent

formatNestedDirectory = ( parentDirectory, packageName ) ->
  if parentDirectory == ""
    "node_modules/#{packageName}"
  else
    "#{parentDirectory}/node_modules/#{packageName}"

resolveNestedDirectory = ( context, path, component, packageName ) ->
  validatePackageName component, packageName
  parentDirectory = resolveParentDirectory context, path
  formatNestedDirectory parentDirectory, packageName

computeDirectory = ( context, path, component ) ->
  if path.length == 0
    resolveRootDirectory context, component
  else
    packageName = getComponentPackageName context, component
    resolveNestedDirectory context, path, component, packageName

resolveDirectory = ( context, path, component ) ->
  cacheKey = "#{component}::#{JSON.stringify path}"
  if context.directoryCache.has cacheKey
    return context.directoryCache.get cacheKey
  directory = computeDirectory context, path, component
  context.directoryCache.set cacheKey, directory
  directory

formatOutputFile = ( physicalDirectory, relativePath ) ->
  normalizedPath =
    if relativePath.startsWith "/"
      relativePath.slice 1
    else
      relativePath
  if physicalDirectory == ""
    normalizedPath
  else
    "#{physicalDirectory}/#{normalizedPath}"

processModule = ( context, physicalDirectory, moduleUrl ) ->
  descriptor = context.metaResolver.decode moduleUrl
  relativePath = descriptor.path
  outputFile = formatOutputFile physicalDirectory, relativePath
  context.bundle.set outputFile, moduleUrl
  return

processComponent = ( context, path, component ) ->
  physicalDirectory = resolveDirectory context, path, component
  modules = ComponentGraph.getModules context.componentGraph, component
  for moduleUrl from modules
    processModule context, physicalDirectory, moduleUrl
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