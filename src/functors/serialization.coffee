import { pipe } from "@dashkite/joy"
import Resolvers from "../resolvers"

toBindingsMap = ( bindings ) ->
  Object.fromEntries bindings

collectSegments = ( node ) ->
  if node.parent?
    [ ( collectSegments node.parent )..., node.segment ]
  else
    []

formatUrl = ( segments ) ->
  "atlas://#{ segments.join "/" }"

getFullUrl = pipe [
  collectSegments
  formatUrl
]

resolveScopeUrl = ( node, resolver ) ->
  resolver.resolve getFullUrl node

recordScope = ( node, resolver ) ->
  if node.bindings.size > 0
    { [ ( resolveScopeUrl node, resolver ) ]: toBindingsMap node.bindings }
  else
    {}

traverseScopes = ( node, resolver ) ->
  {
    ( recordScope node, resolver )...
    ( buildScopes node, resolver )...
  }

mergeChildScopes = ( resolver ) ->
  ( scopes, child ) ->
    { scopes..., ( traverseScopes child, resolver )... }

buildScopes = ( node, resolver ) ->
  ( Array.from node.children.values() ).reduce ( mergeChildScopes resolver ), {}

Serialization =
  apply: ( trie, keys ) ->
    imports: toBindingsMap trie.bindings
    scopes: buildScopes trie, Resolvers.Registry.make keys

export default Serialization