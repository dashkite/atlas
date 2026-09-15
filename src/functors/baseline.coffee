import { URL } from "node:url"
import Trie from "../categories/trie"
import ModuleGraph from "../categories/module-graph"
import { ENTRY_POINT } from "../ingest"

parseSegments = (urlString) ->
  return [] if urlString == ENTRY_POINT
  
  url = new URL(urlString)
  pathSegments = if url.pathname.length > 1
    url.pathname[1..].split "/"
  else
    []
  auth = if url.username then "#{url.username}@#{url.hostname}" else url.hostname
  [auth].concat(pathSegments)

Baseline =
  apply: (moduleGraph) ->
    root = Trie.make()
    
    interEdges = ModuleGraph.getInterEdges moduleGraph
    
    for edge in interEdges
      sourceSegments = parseSegments edge.source
      targetSegments = parseSegments edge.target
      
      sourceNode = Trie.upsertPath root, sourceSegments
      targetNode = Trie.upsertPath root, targetSegments
      
      # Mark package roots so Compaction doesn't hoist past them
      sourcePkgId = ModuleGraph.getAttribute moduleGraph, edge.source, "packageId"
      if sourcePkgId and sourcePkgId != ENTRY_POINT
        pkgNode = Trie.upsertPath root, parseSegments(sourcePkgId)
        pkgNode.isPackage = true
        
      sourceNode.bindings.set edge.label, targetNode
      
    root

export default Baseline
