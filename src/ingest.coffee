import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import Path from "node:path"
import FS from "node:fs"
import nodePreset from "./presets/node"

ENTRY_POINT = Symbol "atlas:entry-point"

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
  items = []
  for await dependency from dependencies
    items.push dependency
  items

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

buildDescriptor = ( target, key, cwd ) ->
  descriptor =
    resolver: key
    path: deriveDescriptorPath target, cwd
  if target.module?
    descriptor.module = deriveModuleMetadata target.module
  descriptor

matchResolverKey = ( metaResolver, target, cwd ) ->
  key = metaResolver.match { source: target.source.path, cwd }
  if !key?
    target = JSON.stringify target
    throw new Error "No resolver found to encode target: #{ target }"
  key

encodeTarget = ( target, metaResolver, cwd ) ->
  key = matchResolverKey metaResolver, target, cwd
  descriptor = buildDescriptor target, key, cwd
  metaResolver.encode descriptor

resolveFileInode = ( cwd, path ) ->
  path = Path.resolve cwd, path
  stat = FS.statSync path
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
  source = resolveSourceUrl item, context
  target = resolveTargetUrl item, context
  { source, target }

resolvePackageId = ( metaResolver, url ) ->
  if url == ENTRY_POINT
    ENTRY_POINT
  else
    parsed = metaResolver.decode url
    parsed.path = ""
    metaResolver.encode parsed

assignPackageId = ( graph, metaResolver, url ) ->
  id = resolvePackageId metaResolver, url
  ModuleGraph.setAttribute graph, url, "packageId", id
  return

registerVertex = ( graph, metaResolver, url ) ->
  ModuleGraph.addVertex graph, url
  assignPackageId graph, metaResolver, url
  return

resolveFileUrl = ( cwd, path ) ->
  path = Path.resolve cwd, path
  ( new URL "file://#{ path }" ).href

recordSources = ( context, item, urls ) ->
  { graph, cwd } = context
  { source, target } = urls
  graph.sources.set target, resolveFileUrl cwd, item.source.path
  if item.import.scope?
    path = item.import.scope.source.path
    graph.sources.set source, resolveFileUrl cwd, path
  return

isRelative = ( specifier ) ->
  ( specifier.startsWith "./" ) || ( specifier.startsWith "../" )

isAlias = ( specifier ) ->
  specifier.startsWith "#"

determineEdgeType = ( specifier ) ->
  if ( isRelative specifier ) || ( isAlias specifier )
    "intra"
  else
    "inter"

recordDependencyEdge = ( graph, urls, specifier ) ->
  type = determineEdgeType specifier
  ModuleGraph.addEdge graph,
    source: urls.source
    target: urls.target
    label: specifier
    type: type
  return

processDependency = ( item, context ) ->
  urls = resolveDependencyUrls item, context
  registerVertex context.graph, context.metaResolver, urls.source
  registerVertex context.graph, context.metaResolver, urls.target
  recordSources context, item, urls
  recordDependencyEdge context.graph, urls, item.import.specifier
  return

processDependencies = ( dependencies, context ) ->
  for item in dependencies
    processDependency item, context
  return

ingest = ( dependencies, options = {} ) ->
  validatePreconditions dependencies, options
  context = createIngestContext options
  dependencies = await collectDependencies dependencies
  processDependencies dependencies, context
  context.graph

export default ingest
export { ingest, ENTRY_POINT }