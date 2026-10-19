import Resolvers from "../resolvers"

toBindingsMap = ( bindings ) ->
  Object.fromEntries bindings

resolveScopeUrl = ( node, resolver ) ->
  resolver.resolve node.getAddress()

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

functor = ( trie, keys ) ->
  imports: toBindingsMap trie.bindings
  scopes: buildScopes trie, Resolvers.Registry.make keys

export default functor