import Resolvers from "../resolvers"

resolve = ( node, registry ) ->
  for [ label, target ] from node.bindings
    node.bindings.set label, registry.resolve target.getAddress()
  return

traverse = ( node, registry ) ->
  resolve node, registry
  for child from node.children.values()
    traverse child, registry
  node

functor = ( trie, keys ) ->
  traverse trie, Resolvers.Registry.make keys

export default functor