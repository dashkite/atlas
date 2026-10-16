import { URL } from "node:url"
import Trie from "../categories/trie"
import { ENTRY_POINT } from "../ingest"

getAuthority = ( url ) ->
  if url.username then "#{url.username}@#{url.hostname}" else url.hostname

getPathSegments = ( url ) ->
  if url.pathname.length > 1 then url.pathname[1..].split "/" else []

getUrlSegments = ( url ) ->
  [ ( getAuthority url ), ( getPathSegments url )... ]

getPackageSegment = ( url ) ->
  ( getUrlSegments url ).join "/"

getRemainingSegments = ( segments, url ) ->
  segments.slice ( getPathSegments url ).length

isExternalPackage = ( id ) ->
  ( id? ) &&
    ( id != ENTRY_POINT ) &&
    ( !( id.startsWith "atlas://application" ) )

parsePackageSegments = ( segments, url ) ->
  [ ( getPackageSegment url ), ( getRemainingSegments segments, url )... ]

parseUrlSegments = ( url, id ) ->
  if isExternalPackage id
    parsePackageSegments ( getPathSegments url ), new URL id
  else
    getUrlSegments url

parseSegments = ( endpoint, id ) ->
  if endpoint == ENTRY_POINT
    []
  else
    parseUrlSegments ( new URL endpoint ), id

resolve = ( root, graph, endpoint ) ->
  root.upsertPath parseSegments endpoint,
    graph.getAttribute endpoint, "packageId"

bindEdge = ( root, graph, { source, target, label } ) ->
  ( resolve root, graph, source ).bindings.set label,
    resolve root, graph, target
  return

functor = ( graph ) ->
  root = Trie.make()
  for edge in graph.getInterEdges()
    bindEdge root, graph, edge
  root

export default functor