import { pipe } from "@dashkite/joy"
import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import Path from "node:path"
import FS from "node:fs/promises"
import preset from "./presets/node"

ENTRY_POINT = Symbol "atlas:entry-point"

resolveCwd = ( options ) ->
  options.cwd ? process.cwd()

resolveRegistry = ( options ) ->
  resolvers = options.resolvers ? preset
  Resolvers.Registry.make resolvers

deriveMetadata = ( module ) ->
  {
    scope: module.scope
    name: module.name
    version: module.version
  }

isRelative = ( specifier ) ->
  ( specifier.startsWith "./" ) || ( specifier.startsWith "../" )

isAlias = ( specifier ) ->
  specifier.startsWith "#"

determineType = ( specifier ) ->
  if ( isRelative specifier ) || ( isAlias specifier )
    "intra"
  else
    "inter"

class ModuleUrlResolver
  @make: ( cwd, registry ) ->
    Object.assign ( new @ ),
      cwd: cwd
      registry: registry
      inodes: new Map()

  derivePath: ( target ) ->
    if target.module?
      "/#{ Path.relative target.module.path, target.source.path }"
    else if Path.isAbsolute target.source.path
      "/#{ Path.relative @cwd, target.source.path }"
    else
      "/#{ target.source.path }"

  buildDescriptor: ( target, key ) ->
    descriptor =
      resolver: key
      path: @derivePath target
    if target.module?
      descriptor.module = deriveMetadata target.module
    descriptor

  matchKey: ( target ) ->
    key = @registry.match { source: target.source.path, cwd: @cwd }
    if !key?
      target = JSON.stringify target
      throw new Error "No resolver found to encode target: #{ target }"
    key

  encodeTarget: ( target ) ->
    key = @matchKey target
    @registry.encode @buildDescriptor target, key

  resolveInode: ( path ) ->
    ( await FS.stat Path.resolve @cwd, path ).ino

  target: ( target ) ->
    inode = await @resolveInode target.source.path
    if @inodes.has inode
      return @inodes.get inode
    url = @encodeTarget target
    @inodes.set inode, url
    url

  source: ( item ) ->
    if item.import.scope?
      @target item.import.scope
    else
      ENTRY_POINT

  dependency: ( item ) ->
    source: await @source item
    target: await @target item

  file: ( path ) ->
    ( new URL "file://#{ Path.resolve @cwd, path }" ).href

class ModuleGraphBuilder
  @make: ( cwd, registry ) ->
    Object.assign ( new @ ),
      registry: registry
      urls: ModuleUrlResolver.make cwd, registry
      graph: ModuleGraph.make()

  resolvePackage: ( url ) ->
    if url == ENTRY_POINT
      ENTRY_POINT
    else
      parsed = @registry.decode url
      parsed.path = ""
      @registry.encode parsed

  assignPackage: ( url ) ->
    @graph.setAttribute url, "packageId",
      @resolvePackage url
    return

  registerVertex: ( url ) ->
    @graph.addVertex url
    @assignPackage url
    return

  recordSource: ( url, target ) ->
    @graph.setSource url, @urls.file target.source.path
    return

  recordSources: ( item, urls ) ->
    @recordSource urls.target, item
    if item.import.scope?
      @recordSource urls.source, item.import.scope
    return

  recordEdge: ( urls, specifier ) ->
    @graph.addEdge
      source: urls.source
      target: urls.target
      label: specifier
      type: determineType specifier
    return

  addDependency: ( item ) ->
    urls = await @urls.dependency item
    @registerVertex urls.source
    @registerVertex urls.target
    @recordSources item, urls
    @recordEdge urls, item.import.specifier
    return

  build: ->
    @graph

createContext = ( dependencies, options = {} ) ->
  cwd = resolveCwd options
  registry = resolveRegistry options
  {
    dependencies
    builder: ModuleGraphBuilder.make cwd, registry
  }

collectDependencies = ( context ) ->
  items = []
  for await dependency from context.dependencies
    items.push dependency
  { context..., dependencies: items }

processDependencies = ( context ) ->
  for item in context.dependencies
    await context.builder.addDependency item
  context

extractGraph = ( { builder } ) ->
  builder.build()

ingest = pipe [
  createContext
  collectDependencies
  processDependencies
  extractGraph
]

export default ingest
export { ingest, ENTRY_POINT, ModuleUrlResolver, ModuleGraphBuilder }