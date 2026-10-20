import { URL } from "node:url"
import Trie from "../categories/trie"
import { ENTRY_POINT } from "../ingest"

getAuthority = ( url ) ->
  if url.username then "#{url.username}@#{url.hostname}" else url.hostname

Package =
  isExternal: ( id ) ->
    ( id? ) &&
      ( id != ENTRY_POINT ) &&
      ( !( id.startsWith "atlas://application" ))

  segment: ( url ) ->
    ( Segments.fromUrl url ).join "/"

  segments: ( segments, url ) ->
    [( Package.segment url ), ( Segments.remaining segments, url )... ]

Segments =
  fromPath: ( url ) ->
    if url.pathname.length > 1 then url.pathname[1..].split "/" else []

  fromUrl: ( url ) ->
    [( getAuthority url ), ( Segments.fromPath url )... ]

  remaining: ( segments, url ) ->
    segments.slice ( Segments.fromPath url ).length

  resolve: ( url, id ) ->
    if Package.isExternal id
      Package.segments ( Segments.fromPath url ), new URL id
    else
      Segments.fromUrl url

  parse: ( endpoint, id ) ->
    if endpoint == ENTRY_POINT
      []
    else
      Segments.resolve ( new URL endpoint ), id

resolve = ( root, graph, endpoint ) ->
  root.upsertPath Segments.parse endpoint,
    graph.getAttribute endpoint, "packageId"

bindEdge = ( root, graph, { source, target, label }) ->
  ( resolve root, graph, source ).bindings.set label,
    resolve root, graph, target
  return

functor = ( graph ) ->
  root = Trie.make()
  for edge in graph.getInterEdges()
    bindEdge root, graph, edge
  root

export default functor