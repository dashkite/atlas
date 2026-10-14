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
      address = Resolution.address target
      value = registry.resolve address
      node.bindings.set label, value
    return

  traverse: (node, registry) ->
    Resolution.resolve node, registry
    for child from node.children.values()
      Resolution.traverse child, registry
    return

  apply: (trie, keys) ->
    registry = Resolvers.Registry.make keys
    Resolution.traverse trie, registry
    trie

export default Resolution