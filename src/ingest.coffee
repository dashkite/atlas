import { pipe } from "@dashkite/joy"
import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import Path from "node:path"
import FS from "node:fs/promises"
import preset from "./presets/node"

ENTRY_POINT = Symbol "atlas:entry-point"

createGraph = ->
  Object.assign ModuleGraph.make(),
    sources: new Map()

resolveCwd = ( options ) ->
  options.cwd ? process.cwd()

resolveRegistry = ( options ) ->
  resolvers = options.resolvers ? preset
  options.metaResolver ? Resolvers.Registry.make resolvers

createContext = ( dependencies, options = {} ) ->
  {
    dependencies
    cwd: resolveCwd options
    registry: resolveRegistry options
    graph: createGraph()
    inodes: new Map()
  }

collectDependencies = ( context ) ->
  items = []
  for await dependency from context.dependencies
    items.push dependency
  { context..., dependencies: items }

deriveMetadata = ( module ) ->
  {
    scope: module.scope
    name: module.name
    version: module.version
  }

derivePath = ( target, cwd ) ->
  if target.module?
    "/#{ Path.relative target.module.path, target.source.path }"
  else if Path.isAbsolute target.source.path
    "/#{ Path.relative cwd, target.source.path }"
  else
    "/#{ target.source.path }"

buildDescriptor = ( target, key, cwd ) ->
  descriptor =
    resolver: key
    path: derivePath target, cwd
  if target.module?
    descriptor.module = deriveMetadata target.module
  descriptor

matchKey = ( registry, target, cwd ) ->
  key = registry.match { source: target.source.path, cwd }
  if !key?
    target = JSON.stringify target
    throw new Error "No resolver found to encode target: #{ target }"
  key

encodeTarget = ( target, registry, cwd ) ->
  key = matchKey registry, target, cwd
  registry.encode buildDescriptor target, key, cwd

resolveInode = ( cwd, path ) ->
  ( await FS.stat Path.resolve cwd, path ).ino

Urls =
  target: ( target, context ) ->
    inode = await resolveInode context.cwd, target.source.path
    if context.inodes.has inode
      return context.inodes.get inode
    url = encodeTarget target, context.registry, context.cwd
    context.inodes.set inode, url
    url

  source: ( item, context ) ->
    if item.import.scope?
      Urls.target item.import.scope, context
    else
      ENTRY_POINT

  dependency: ( item, context ) ->
    source: await Urls.source item, context
    target: await Urls.target item, context

  file: ( cwd, path ) ->
    ( new URL "file://#{ Path.resolve cwd, path }" ).href

resolvePackage = ( registry, url ) ->
  if url == ENTRY_POINT
    ENTRY_POINT
  else
    parsed = registry.decode url
    parsed.path = ""
    registry.encode parsed

assignPackage = ( graph, registry, url ) ->
  graph.setAttribute url, "packageId",
    resolvePackage registry, url
  return

registerVertex = ( graph, registry, url ) ->
  graph.addVertex url
  assignPackage graph, registry, url
  return

recordSource = ( { graph, cwd }, url, target ) ->
  graph.sources.set url, Urls.file cwd, target.source.path
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

determineType = ( specifier ) ->
  if ( isRelative specifier ) || ( isAlias specifier )
    "intra"
  else
    "inter"

recordEdge = ( graph, urls, specifier ) ->
  graph.addEdge
    source: urls.source
    target: urls.target
    label: specifier
    type: determineType specifier
  return

processDependency = ( item, context ) ->
  urls = await Urls.dependency item, context
  registerVertex context.graph, context.registry, urls.source
  registerVertex context.graph, context.registry, urls.target
  recordSources context, item, urls
  recordEdge context.graph, urls, item.import.specifier
  return

processDependencies = ( context ) ->
  for item in context.dependencies
    await processDependency item, context
  context

extractGraph = ( context ) ->
  context.graph

ingest = pipe [
  createContext
  collectDependencies
  processDependencies
  extractGraph
]

export default ingest
export { ingest, ENTRY_POINT }