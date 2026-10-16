import { pipe } from "@dashkite/joy"
import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import Path from "node:path"
import FS from "node:fs/promises"
import nodePreset from "./presets/node"

ENTRY_POINT = Symbol "atlas:entry-point"

createModuleGraph = ->
  Object.assign ModuleGraph.make(),
    sources: new Map()

resolveCwd = ( options ) ->
  options.cwd ? process.cwd()

resolveMetaResolver = ( options ) ->
  resolvers = options.resolvers ? nodePreset
  options.metaResolver ? Resolvers.Registry.make resolvers

createIngestContext = ( dependencies, options = {} ) ->
  {
    dependencies
    cwd: resolveCwd options
    metaResolver: resolveMetaResolver options
    graph: createModuleGraph()
    inodeCache: new Map()
  }

collectDependencies = ( context ) ->
  items = []
  for await dependency from context.dependencies
    items.push dependency
  { context..., dependencies: items }

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
  metaResolver.encode buildDescriptor target, key, cwd

resolveFileInode = ( cwd, path ) ->
  ( await FS.stat Path.resolve cwd, path ).ino

resolveTargetUrl = ( target, context ) ->
  inode = await resolveFileInode context.cwd, target.source.path
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
  source: await resolveSourceUrl item, context
  target: await resolveTargetUrl item, context

resolvePackageId = ( metaResolver, url ) ->
  if url == ENTRY_POINT
    ENTRY_POINT
  else
    parsed = metaResolver.decode url
    parsed.path = ""
    metaResolver.encode parsed

assignPackageId = ( graph, metaResolver, url ) ->
  graph.setAttribute url, [
    "packageId"
    resolvePackageId metaResolver, url
  ]
  return

registerVertex = ( graph, metaResolver, url ) ->
  graph.addVertex url
  assignPackageId graph, metaResolver, url
  return

resolveFileUrl = ( cwd, path ) ->
  ( new URL "file://#{ Path.resolve cwd, path }" ).href

recordSource = ( { graph, cwd }, url, target ) ->
  graph.sources.set url, resolveFileUrl cwd, target.source.path
  return

recordSources = ( context, item, urls ) ->
  recordSource context, urls.target, item
  if item.import.scope?
    recordSource context, urls.source, item.import.scope
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
  graph.addEdge
    source: urls.source
    target: urls.target
    label: specifier
    type: determineEdgeType specifier
  return

processDependency = ( item, context ) ->
  urls = await resolveDependencyUrls item, context
  registerVertex context.graph, context.metaResolver, urls.source
  registerVertex context.graph, context.metaResolver, urls.target
  recordSources context, item, urls
  recordDependencyEdge context.graph, urls, item.import.specifier
  return

processDependencies = ( context ) ->
  for item in context.dependencies
    await processDependency item, context
  context

extractGraph = ( context ) ->
  context.graph

ingest = pipe [
  createIngestContext
  collectDependencies
  processDependencies
  extractGraph
]

export default ingest
export { ingest, ENTRY_POINT }