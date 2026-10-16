import { pipe } from "@dashkite/joy"
import Resolvers from "../resolvers"

segments = ( node ) ->
  if node.parent?
    [ ( segments node.parent )..., node.segment ]
  else
    []

format = ( parts ) ->
  "atlas://#{parts.join "/"}"

address = pipe [
  segments
  format
]

resolve = ( node, registry ) ->
  for [ label, target ] from node.bindings
    node.bindings.set label, registry.resolve address target
  return

traverse = ( node, registry ) ->
  resolve node, registry
  for child from node.children.values()
    traverse child, registry
  node

apply = ( trie, keys ) ->
  traverse trie, Resolvers.Registry.make keys

Resolution = {
  segments
  format
  address
  resolve
  traverse
  apply
}

export default Resolution