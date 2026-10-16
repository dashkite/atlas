import Resolvers from "../resolvers"

Resolution =
  segments: (node) ->
    segments = []
    current = node
    while current.parent?
      segments.unshift current.segment
      current = current.parent
    segments

  format: (segments) ->
    host = segments[0]
    path = segments[1..].join "/"
    if path.length > 0
      "atlas://#{host}/#{path}"
    else
      "atlas://#{host}"

  address: (node) ->
    Resolution.format Resolution.segments node

  resolve: (node, registry) ->
    for [label, target] from node.bindings
      node.bindings.set label, registry.resolve Resolution.address target
    return

  traverse: (node, registry) ->
    Resolution.resolve node, registry
    for child from node.children.values()
      Resolution.traverse child, registry
    node

  apply: (trie, keys) ->
    Resolution.traverse trie, Resolvers.Registry.make keys

export default Resolution