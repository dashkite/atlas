import { URL } from "node:url"
import Trie from "../categories/trie"
import ModuleGraph from "../categories/module-graph"
import { ENTRY_POINT } from "../ingest"

parseSegments = (urlString, packageId) ->
  return [] if urlString == ENTRY_POINT
  
  url = new URL(urlString)
  pathSegments = if url.pathname.length > 1
    url.pathname[1..].split "/"
  else
    []
  auth = if url.username then "#{url.username}@#{url.hostname}" else url.hostname
  
  if packageId and packageId != ENTRY_POINT and not packageId.startsWith("atlas://application")
    pkgUrl = new URL(packageId)
    pkgPathSegments = if pkgUrl.pathname.length > 1 then pkgUrl.pathname[1..].split "/" else []
    pkgAuth = if pkgUrl.username then "#{pkgUrl.username}@#{pkgUrl.hostname}" else pkgUrl.hostname
    
    # The atomic package segment is the auth + all package path segments joined by /
    pkgSegment = [pkgAuth].concat(pkgPathSegments).join("/")
    
    # The remaining segments are whatever comes after the package segments
    # Since urlString is a descendant of packageId, it has the same auth and prefix path
    remainingSegments = pathSegments.slice(pkgPathSegments.length)
    return [pkgSegment].concat(remainingSegments)
    
  [auth].concat(pathSegments)

Baseline =
  apply: (moduleGraph) ->
    root = Trie.make()
    
    interEdges = ModuleGraph.getInterEdges moduleGraph
    
    for edge in interEdges
      sourcePkgId = ModuleGraph.getAttribute moduleGraph, edge.source, "packageId"
      targetPkgId = ModuleGraph.getAttribute moduleGraph, edge.target, "packageId"
      
      sourceSegments = parseSegments edge.source, sourcePkgId
      targetSegments = parseSegments edge.target, targetPkgId
      
      sourceNode = Trie.upsertPath root, sourceSegments
      targetNode = Trie.upsertPath root, targetSegments
      
      # Mark package roots so Compaction knows where they are
      if sourcePkgId and sourcePkgId != ENTRY_POINT and not sourcePkgId.startsWith("atlas://application")
        pkgNode = Trie.upsertPath root, parseSegments(sourcePkgId, sourcePkgId)
        pkgNode.isPackage = true
        
      sourceNode.bindings.set edge.label, targetNode
      
    root

export default Baseline
