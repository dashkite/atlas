import ModuleGraph from "./categories/module-graph"
import Resolvers from "./resolvers"
import AtlasURL from "./url"
import Path from "node:path"

import FS from "node:fs"

import nodePreset from "./presets/node"

ingest = ( dependencies, options = {} ) ->
  graph = ModuleGraph.make()
  cwd = options.cwd ? options.root ? process.cwd()
  resolvers = options.resolvers ? nodePreset options
  
  # A map to store physical file paths for bundler consumption later
  graph.sources = new Map()
  inodeCache = new Map()

  rawDeps = []
  for await dep from dependencies
    rawDeps.push dep if dep?
    
  encode = (target) ->
    resolver = resolvers.find (r) -> r.match target, options
    unless resolver?
      throw new Error "No resolver found to encode target: #{ JSON.stringify target }"
    resolver.encode target, options
    
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
    # Encode URLs using configured resolvers
    sourceUrl = if item.import?.scope?
      encodeCached item.import.scope
    else
      "atlas://virtual-root"
      
    targetUrl = encodeCached item
    specifier = item.import.specifier

    ModuleGraph.addVertex graph, sourceUrl
    ModuleGraph.addVertex graph, targetUrl

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
