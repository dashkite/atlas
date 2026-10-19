import Resolvers from "../resolvers"

toMap = ( bindings ) ->
  Object.fromEntries bindings

Scopes =

  resolve: ( node, resolver ) ->
    resolver.resolve node.getAddress()

  record: ( node, resolver ) ->
    if node.bindings.size > 0
      { [ ( Scopes.resolve node, resolver ) ]: toMap node.bindings }
    else
      {}

  traverse: ( node, resolver ) ->
    {
      ( Scopes.record node, resolver )...
      ( Scopes.build node, resolver )...
    }

  merge: ( resolver ) ->
    ( scopes, child ) ->
      { scopes..., ( Scopes.traverse child, resolver )... }

  build: ( node, resolver ) ->
    ( Array.from node.children.values() ).reduce ( Scopes.merge resolver ), {}

functor = ( trie, keys ) ->
  imports: toMap trie.bindings
  scopes: Scopes.build trie, Resolvers.Registry.make keys

export default functor