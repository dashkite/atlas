import { URL } from "node:url"
import Trie from "../categories/trie"
import { entryPoint } from "../ingest"

getAuthority = ( url ) ->
  if url.username then "#{url.username}@#{url.hostname}" else url.hostname

Package =
  isExternal: ( id ) ->
    ( id? ) &&
      ( id != entryPoint ) &&
      ( !( id.startsWith "atlas://application" ))

  segment: ( url ) ->
    ( Segments.fromURL url ).join "/"

  segments: ( segments, url ) ->
    [( Package.segment url ), ( Segments.remaining segments, url )... ]

Segments =
  fromPath: ( url ) ->
    if url.pathname.length > 1 then url.pathname[ 1.. ].split "/" else []

  fromURL: ( url ) ->
    [( getAuthority url ), ( Segments.fromPath url )... ]

  remaining: ( segments, url ) ->
    segments.slice ( Segments.fromPath url ).length

  resolve: ( url, id ) ->
    if Package.isExternal id
      Package.segments ( Segments.fromPath url ), new URL id
    else
      Segments.fromURL url

  parse: ( endpoint, id ) ->
    if endpoint == entryPoint
      []
    else
      Segments.resolve ( new URL endpoint ), id

resolve = ( root, graph, endpoint ) ->
  id = graph.getAttribute endpoint, "packageId"
  segments = Segments.parse endpoint, id
  root.upsertPath segments

bindEdge = ( root, graph, { source, target, label }) ->
  ( resolve root, graph, source )
    .bindings
    .set label,
      resolve root, graph, target
  return

functor = ( graph ) ->
  root = Trie.make()
  for edge in graph.getInterEdges()
    bindEdge root, graph, edge
  root

export default functor