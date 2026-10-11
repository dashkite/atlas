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

parsePackageSegments = ( pathSegments, packageId ) ->
  packageUrl = new URL packageId
  packageAuthority = getAuthority packageUrl
  packagePathSegments = getPathSegments packageUrl
  packageSegment = [ packageAuthority, packagePathSegments... ].join "/"
  remainingSegments = pathSegments.slice packagePathSegments.length
  [ packageSegment, remainingSegments... ]

parseUrlSegments = ( url, packageId ) ->
  pathSegments = getPathSegments url
  if isExternalPackage packageId
    parsePackageSegments pathSegments, packageId
  else
    authority = getAuthority url
    [ authority, pathSegments... ]

parseSegments = ( urlString, packageId ) ->
  if urlString == ENTRY_POINT
    []
  else
    url = new URL urlString
    parseUrlSegments url, packageId

markPackageRoot = ( root, packageId ) ->
  if isExternalPackage packageId
    packageNode = Trie.upsertPath root, ( parseSegments packageId, packageId )
    packageNode.isPackage = true

bindEdge = ( root, moduleGraph, edge ) ->
  { source, target, label } = edge
  sourcePackageId = ModuleGraph.getAttribute moduleGraph, source, "packageId"
  targetPackageId = ModuleGraph.getAttribute moduleGraph, target, "packageId"
  sourceSegments = parseSegments source, sourcePackageId
  targetSegments = parseSegments target, targetPackageId
  sourceNode = Trie.upsertPath root, sourceSegments
  targetNode = Trie.upsertPath root, targetSegments
  markPackageRoot root, sourcePackageId
  sourceNode.bindings.set label, targetNode

Baseline =
  apply: ( moduleGraph ) ->
    root = Trie.make()
    for edge in ModuleGraph.getInterEdges moduleGraph
      bindEdge root, moduleGraph, edge
    root

export default Baseline