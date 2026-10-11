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

resolveBindings = (node, metaResolver) ->
  for [label, target] from node.bindings
    targetUrl = getFullUrl target
    mappedString = metaResolver.resolve targetUrl
    node.bindings.set label, mappedString
  return

traverse = (node, metaResolver) ->
  resolveBindings node, metaResolver
  for childNode from node.children.values()
    traverse childNode, metaResolver
  return

Resolution =
  apply: (trie, keys) ->
    metaResolver = Resolvers.Registry.make keys
    traverse trie, metaResolver
    trie

export default Resolution