import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import AtlasURL from "./url"
import Path from "node:path"

import FS from "node:fs"

import nodePreset from "./presets/node"

export ENTRY_POINT = Symbol "atlas:entry-point"

ingest = ( dependencies, options = {} ) ->
  graph = ModuleGraph.make()
  cwd = options.cwd ? options.root ? process.cwd()
  resolvers = options.resolvers ? nodePreset
  
  # A map to store physical file paths for bundler consumption later
  graph.sources = new Map()
  inodeCache = new Map()

  rawDeps = []
  for await dep from dependencies
    rawDeps.push dep if dep?
    
  metaResolver = options.metaResolver ? Resolvers.Registry.make resolvers
  
  encode = (target) ->
    resolverKey = metaResolver.match { source: target.source.path, cwd }
    unless resolverKey?
      throw new Error "No resolver found to encode target: #{ JSON.stringify target }"
      
    descriptor = { resolver: resolverKey }
    
    if target.module?
      descriptor.module = {
        scope: target.module.scope
        name: target.module.name
        version: target.module.version
      }
      subpath = Path.relative target.module.path, target.source.path
      descriptor.path = "/" + subpath
    else
      descriptor.path = if Path.isAbsolute target.source.path
        "/" + Path.relative cwd, target.source.path
      else
        "/" + target.source.path
      
    metaResolver.encode descriptor
  encodeCached = (target) ->
    stat = null
    if target.source?.path?
      absPath = Path.resolve cwd, target.source.path
      try
        stat = FS.statSync absPath
        if inodeCache.has stat.ino
          return inodeCache.get stat.ino
      catch
        null

    url = encode target
    
    if stat?
      inodeCache.set stat.ino, url
      
    url

  for item in rawDeps
    sourceUrl = if item.import?.scope?
      encodeCached item.import.scope
    else
      ENTRY_POINT
      
    targetUrl = encodeCached item
    specifier = item.import.specifier

    ModuleGraph.addVertex graph, sourceUrl
    ModuleGraph.addVertex graph, targetUrl

    if sourceUrl == ENTRY_POINT
      sourcePackageId = ENTRY_POINT
    else
      sourceParsed = metaResolver.decode sourceUrl
      sourceParsed.path = ""
      sourcePackageId = metaResolver.encode sourceParsed
    ModuleGraph.setAttribute graph, sourceUrl, "packageId", sourcePackageId

    if targetUrl == ENTRY_POINT
      targetPackageId = ENTRY_POINT
    else
      targetParsed = metaResolver.decode targetUrl
      targetParsed.path = ""
      targetPackageId = metaResolver.encode targetParsed
    ModuleGraph.setAttribute graph, targetUrl, "packageId", targetPackageId

    # Save physical locations on disk
    if item.source?.path?
      absPath = Path.resolve cwd, item.source.path
      graph.sources.set targetUrl, new URL("file://#{absPath}").href
    if item.import?.scope?.source?.path?
      scopeAbsPath = Path.resolve cwd, item.import.scope.source.path
      graph.sources.set sourceUrl, new URL("file://#{scopeAbsPath}").href

    # Determine morphism partition
    isRel = specifier.startsWith("./") || specifier.startsWith("../")
    isAlias = specifier.startsWith("#")
    
    edgeType = if isRel || isAlias then "intra" else "inter"

    ModuleGraph.addEdge graph,
      source: sourceUrl
      target: targetUrl
      label: specifier
      type: edgeType

  graph

export default ingest
