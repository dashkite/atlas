import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import Path from "node:path"
import FS from "node:fs/promises"

entryPoint = Symbol "atlas:entry-point"

deriveMetadata = ( module ) ->
  {
    scope: module.scope
    name: module.name
    version: module.version
  }

Specifier =
  isRelative: ( specifier ) ->
    ( specifier.startsWith "./" ) || ( specifier.startsWith "../" )

  isAlias: ( specifier ) ->
    specifier.startsWith "#"

  determineType: ( specifier ) ->
    if ( Specifier.isRelative specifier ) || ( Specifier.isAlias specifier )
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
      throw new Error (
        "No resolver found to encode target: #{ JSON.stringify target }"
      )

  encodeTarget: ( target ) ->
    @registry.encode @buildDescriptor target, @matchKey target

  target: ( target ) ->
    inode = ( await FS.stat Path.resolve @cwd, target.source.path ).ino
    if !@inodes.has inode
      @inodes.set inode, @encodeTarget target
    @inodes.get inode

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

  resolvePackage: ( url ) ->
    if url == entryPoint
      entryPoint
    else
      parsed = @registry.decode url
      @registry.encode { parsed..., path: "" }

  registerVertex: ( url ) ->
    @graph.addVertex url
    @graph.setAttribute url, "packageId", @resolvePackage url
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
      type: Specifier.determineType specifier
    return

  addDependency: ( item ) ->
    urls = await @urls.dependency item
    @registerVertex urls.source
    @registerVertex urls.target
    @recordSources item, urls
    @recordEdge urls, item.import.specifier

  build: ->
    @graph

ingest = ( dependencies, { cwd, resolvers }) ->
  registry = Resolvers.Registry.make resolvers
  builder = ModuleGraphBuilder.make cwd, registry
  for await item from dependencies
    await builder.addDependency item
  builder.build()

export default ingest
export { ingest, entryPoint, ModuleURLResolver, ModuleGraphBuilder }
