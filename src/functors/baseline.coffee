import { URL } from "node:url"
import Trie from "../categories/trie"
import ModuleGraph from "../categories/module-graph"
import { ENTRY_POINT } from "../ingest"

getAuthority = ( url ) ->
  if url.username then "#{url.username}@#{url.hostname}" else url.hostname

getPathSegments = ( url ) ->
  if url.pathname.length > 1 then url.pathname[1..].split "/" else []

isExternalPackage = ( id ) ->
  ( id? ) &&
    ( id != ENTRY_POINT ) &&
    ( !( id.startsWith "atlas://application" ) )

parsePackageSegments = ( segments, id ) ->
  url = new URL id
  authority = getAuthority url
  path = getPathSegments url
  segment = [ authority, path... ].join "/"
  remaining = segments.slice path.length
  [ segment, remaining... ]

parseUrlSegments = ( url, id ) ->
  segments = getPathSegments url
  if isExternalPackage id
    parsePackageSegments segments, id
  else
    authority = getAuthority url
    [ authority, segments... ]

parseSegments = ( endpoint, id ) ->
  if endpoint == ENTRY_POINT
    []
  else
    url = new URL endpoint
    parseUrlSegments url, id

markPackageRoot = ( root, id ) ->
  if isExternalPackage id
    node = Trie.upsertPath root, ( parseSegments id, id )
    node.isPackage = true

resolve = ( root, graph, endpoint ) ->
  id = ModuleGraph.getAttribute graph, endpoint, "packageId"
  segments = parseSegments endpoint, id
  node = Trie.upsertPath root, segments
  { node, id }

bindEdge = ( root, graph, edge ) ->
  source = resolve root, graph, edge.source
  target = resolve root, graph, edge.target
  markPackageRoot root, source.id
  source.node.bindings.set edge.label, target.node

Baseline =
  apply: ( graph ) ->
    root = Trie.make()
    for edge in ModuleGraph.getInterEdges graph
      bindEdge root, graph, edge
    root

export default Baseline