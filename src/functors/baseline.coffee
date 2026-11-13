import { URL } from "node:url"
import Trie from "../categories/trie"
import { entryPoint } from "../ingest"

getAuthority = ( url ) ->
  if url.username then "#{url.username}@#{url.hostname}" else url.hostname

Package =
  isExternal: ( id ) ->
    ( id != entryPoint ) && !( id.startsWith "atlas://application" )

Segments =
  fromPath: ( url ) ->
    if url.pathname.length > 1 then url.pathname[ 1.. ].split "/" else []

  fromURL: ( url ) ->
    [( getAuthority url ), ( Segments.fromPath url )... ]

  fromExternal: ( url, id ) ->
    base = new URL id
    prefix = ( Segments.fromURL base ).join "/"
    offset = ( Segments.fromPath base ).length
    [ prefix, (( Segments.fromPath url ).slice offset )... ]

  parse: ( endpoint, id ) ->
    if endpoint == entryPoint
      []
    else if Package.isExternal id
      Segments.fromExternal ( new URL endpoint ), id
    else
      Segments.fromURL new URL endpoint

resolve = ( root, graph, endpoint ) ->
  root.upsertPath do ->
    Segments.parse endpoint,
      graph.getAttribute endpoint, "packageId"

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