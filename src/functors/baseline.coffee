import { URL } from "node:url"
import Trie from "../categories/trie"
import ModuleGraph from "../categories/module-graph"
import { ENTRY_POINT } from "../ingest"

getAuthority = ( url ) ->
  if url.username then "#{url.username}@#{url.hostname}" else url.hostname

getPathSegments = ( url ) ->
  if url.pathname.length > 1 then url.pathname[1..].split "/" else []

isExternalPackage = ( packageId ) ->
  ( packageId? ) &&
    ( packageId != ENTRY_POINT ) &&
    ( !( packageId.startsWith "atlas://application" ) )

parsePackageSegments = ( segments, packageId ) ->
  url = new URL packageId
  authority = getAuthority url
  path = getPathSegments url
  segment = [ authority, path... ].join "/"
  remaining = segments.slice path.length
  [ segment, remaining... ]

parseUrlSegments = ( url, packageId ) ->
  segments = getPathSegments url
  if isExternalPackage packageId
    parsePackageSegments segments, packageId
  else
    authority = getAuthority url
    [ authority, segments... ]

parseSegments = ( urlString, packageId ) ->
  if urlString == ENTRY_POINT
    []
  else
    url = new URL urlString
    parseUrlSegments url, packageId

markPackageRoot = ( root, packageId ) ->
  if isExternalPackage packageId
    node = Trie.upsertPath root, ( parseSegments packageId, packageId )
    node.isPackage = true

resolve = ( root, moduleGraph, endpoint ) ->
  packageId = ModuleGraph.getAttribute moduleGraph, endpoint, "packageId"
  segments = parseSegments endpoint, packageId
  node = Trie.upsertPath root, segments
  { node, packageId }

bindEdge = ( root, moduleGraph, edge ) ->
  source = resolve root, moduleGraph, edge.source
  target = resolve root, moduleGraph, edge.target
  markPackageRoot root, source.packageId
  source.node.bindings.set edge.label, target.node

Baseline =
  apply: ( moduleGraph ) ->
    root = Trie.make()
    for edge in ModuleGraph.getInterEdges moduleGraph
      bindEdge root, moduleGraph, edge
    root

export default Baseline