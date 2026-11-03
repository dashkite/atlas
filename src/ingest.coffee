import { pipe } from "@dashkite/joy"
import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import Path from "node:path"
import FS from "node:fs/promises"
import preset from "./presets/node"

entryPoint = Symbol "atlas:entry-point"

resolveCWD = ( options ) ->
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

class ModuleURLResolver
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
    key = @registry.match { source: target.source.path, @cwd }
    if key?
      key
    else
      throw new Error \
        "No resolver found to encode target: #{ JSON.stringify target }"

  encodeTarget: ( target ) ->
    @registry.encode @buildDescriptor target, @matchKey target

  resolveInode: ( path ) ->
    ( await FS.stat Path.resolve @cwd, path ).ino

  cacheTarget: ( inode, target ) ->
    if !@inodes.has inode
      @inodes.set inode, @encodeTarget target
    @inodes.get inode

  target: ( target ) ->
    inode = await @resolveInode target.source.path
    @cacheTarget inode, target

  source: ( item ) ->
    if item.import.scope?
      @target item.import.scope
    else
      entryPoint

  dependency: ( item ) ->
    source: await @source item
    target: await @target item

  file: ( path ) ->
    ( new URL "file://#{ Path.resolve @cwd, path }" ).href

class ModuleGraphBuilder
  @make: ( cwd, registry ) ->
    Object.assign ( new @ ),
      registry: registry
      urls: ModuleURLResolver.make cwd, registry
      graph: ModuleGraph.make()

  encodePackage: pipe [
    ( url ) -> @registry.decode url
    ( parsed ) -> { parsed..., path: "" }
    ( parsed ) -> @registry.encode parsed
  ]

  resolvePackage: ( url ) ->
    if url == entryPoint
      entryPoint
    else
      @encodePackage url

  assignPackage: ( url ) ->
    @graph.setAttribute url, "packageId",
      @resolvePackage url
    return

  registerVertex: ( url ) ->
    @graph.addVertex url
    @assignPackage url
    return

  registerVertices: ( urls ) ->
    @registerVertex urls.source
    @registerVertex urls.target
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
    @registerVertices urls
    @recordSources item, urls
    @recordEdge urls, item.import.specifier

  build: ->
    @graph

createBuilder = ( options = {}) ->
  ModuleGraphBuilder.make ( resolveCWD options ),
    ( resolveRegistry options )

ingest = ( dependencies, options = {}) ->
  builder = createBuilder options
  for await item from dependencies
    await builder.addDependency item
  builder.build()

export default ingest
export { ingest, entryPoint, ModuleURLResolver, ModuleGraphBuilder }