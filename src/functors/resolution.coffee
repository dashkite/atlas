import Resolvers from "../resolvers"

getNodeSegments = (node) ->
  segments = []
  current = node
  while current.parent?
    segments.unshift current.segment
    current = current.parent
  segments

formatAtlasUrl = (segments) ->
  host = segments[0]
  path = segments[1..].join "/"
  if path.length > 0
    "atlas://#{host}/#{path}"
  else
    "atlas://#{host}"

getFullUrl = (node) ->
  formatAtlasUrl getNodeSegments node

resolveBindings = (node, registry) ->
  for [label, target] from node.bindings
    url = getFullUrl target
    value = registry.resolve url
    node.bindings.set label, value
  return

traverse = (node, registry) ->
  resolveBindings node, registry
  for child from node.children.values()
    traverse child, registry
  return

Resolution =
  apply: (trie, keys) ->
    registry = Resolvers.Registry.make keys
    traverse trie, registry
    trie

export default Resolution