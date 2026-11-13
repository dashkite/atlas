import Resolvers from "../resolvers"

collectScopes = ( parent, resolver, scopes ) ->
  for child from parent.children.values()
    if child.bindings.size > 0
      key = resolver.resolve child.getAddress()
      scopes[ key ] = Object.fromEntries child.bindings
    collectScopes child, resolver, scopes
  scopes

functor = ( trie, keys ) ->
  resolver = Resolvers.Registry.make keys
  imports: Object.fromEntries trie.bindings
  scopes: collectScopes trie, resolver, {}

export default functor