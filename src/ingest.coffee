import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import Path from "node:path"
import FS from "node:fs"
import nodePreset from "./presets/node"

export ENTRY_POINT = Symbol "atlas:entry-point"

validatePreconditions = ( dependencies, options ) ->
  if !dependencies?
    throw new Error "Dependencies argument is required"
  isIterable = ( typeof dependencies[ Symbol.iterator ] == "function" ) ||
    ( typeof dependencies[ Symbol.asyncIterator ] == "function" )
  if !isIterable
    throw new Error "Dependencies must be an iterable or async iterable"
  if ( typeof options != "object" ) || ( !options? )
    throw new Error "Options must be an object"

createModuleGraph = ->
  graph = ModuleGraph.make()
  graph.sources = new Map()
  graph

resolveCwd = ( options ) ->
  options.cwd ? options.root ? process.cwd()

resolveMetaResolver = ( options ) ->
  resolvers = options.resolvers ? nodePreset
  options.metaResolver ? Resolvers.Registry.make resolvers

createIngestContext = ( options ) ->
  {
    cwd: resolveCwd options
    metaResolver: resolveMetaResolver options
    graph: createModuleGraph()
    inodeCache: new Map()
  }

collectDependencies = ( dependencies ) ->
  rawDependencies = []
  for await dependency from dependencies
    rawDependencies.push dependency
  rawDependencies

deriveModuleMetadata = ( module ) ->
  {
    scope: module.scope
    name: module.name
    version: module.version
  }

deriveDescriptorPath = ( target, cwd ) ->
  if target.module?
    "/#{ Path.relative target.module.path, target.source.path }"
  else if Path.isAbsolute target.source.path
    "/#{ Path.relative cwd, target.source.path }"
  else
    "/#{ target.source.path }"

buildDescriptor = ( target, resolverKey, cwd ) ->
  descriptor =
    resolver: resolverKey
    path: deriveDescriptorPath target, cwd
  if target.module?
    descriptor.module = deriveModuleMetadata target.module
  descriptor

matchResolverKey = ( metaResolver, target, cwd ) ->
  resolverKey = metaResolver.match { source: target.source.path, cwd }
  if !resolverKey?
    serializedTarget = JSON.stringify target
    throw new Error "No resolver found to encode target: #{ serializedTarget }"
  resolverKey

encodeTarget = ( target, metaResolver, cwd ) ->
  resolverKey = matchResolverKey metaResolver, target, cwd
  descriptor = buildDescriptor target, resolverKey, cwd
  metaResolver.encode descriptor

resolveFileInode = ( cwd, sourcePath ) ->
  absolutePath = Path.resolve cwd, sourcePath
  stat = FS.statSync absolutePath
  stat.ino

resolveTargetUrl = ( target, context ) ->
  inode = resolveFileInode context.cwd, target.source.path
  if context.inodeCache.has inode
    return context.inodeCache.get inode
  url = encodeTarget target, context.metaResolver, context.cwd
  context.inodeCache.set inode, url
  url

resolveSourceUrl = ( item, context ) ->
  if item.import.scope?
    resolveTargetUrl item.import.scope, context
  else
    ENTRY_POINT

resolveDependencyUrls = ( item, context ) ->
  sourceUrl = resolveSourceUrl item, context
  targetUrl = resolveTargetUrl item, context
  { sourceUrl, targetUrl }

resolvePackageId = ( metaResolver, url ) ->
  if url == ENTRY_POINT
    ENTRY_POINT
  else
    parsed = metaResolver.decode url
    parsed.path = ""
    metaResolver.encode parsed

assignPackageId = ( graph, metaResolver, url ) ->
  packageId = resolvePackageId metaResolver, url
  ModuleGraph.setAttribute graph, url, "packageId", packageId
  return

registerVertex = ( graph, metaResolver, url ) ->
  ModuleGraph.addVertex graph, url
  assignPackageId graph, metaResolver, url
  return

resolveFileUrl = ( cwd, filePath ) ->
  absolutePath = Path.resolve cwd, filePath
  ( new URL "file://#{ absolutePath }" ).href

recordSources = ( context, item, urls ) ->
  { graph, cwd } = context
  { sourceUrl, targetUrl } = urls
  graph.sources.set targetUrl, resolveFileUrl cwd, item.source.path
  if item.import.scope?
    sourcePath = item.import.scope.source.path
    graph.sources.set sourceUrl, resolveFileUrl cwd, sourcePath
  return

determineEdgeType = ( specifier ) ->
  isRelative = ( specifier.startsWith "./" ) || ( specifier.startsWith "../" )
  isAlias = specifier.startsWith "#"
  if isRelative || isAlias
    "intra"
  else
    "inter"

recordDependencyEdge = ( graph, urls, specifier ) ->
  edgeType = determineEdgeType specifier
  ModuleGraph.addEdge graph,
    source: urls.sourceUrl
    target: urls.targetUrl
    label: specifier
    type: edgeType
  return

processDependency = ( item, context ) ->
  urls = resolveDependencyUrls item, context
  registerVertex context.graph, context.metaResolver, urls.sourceUrl
  registerVertex context.graph, context.metaResolver, urls.targetUrl
  recordSources context, item, urls
  recordDependencyEdge context.graph, urls, item.import.specifier
  return

processDependencies = ( rawDependencies, context ) ->
  for item in rawDependencies
    processDependency item, context
  return

ingest = ( dependencies, options = {} ) ->
  validatePreconditions dependencies, options
  context = createIngestContext options
  rawDependencies = await collectDependencies dependencies
  processDependencies rawDependencies, context
  context.graph

export default ingest
export { ingest }