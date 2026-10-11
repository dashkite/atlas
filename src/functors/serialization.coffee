import Resolvers from "../resolvers"

toBindingsMap = (bindings) ->
  map = {}
  for [label, target] from bindings
    map[label] = target
  map

collectSegments = (node) ->
  segments = []
  current = node
  while current.parent?
    segments.unshift current.segment
    current = current.parent
  segments

formatUrl = (segments) ->
  host = segments[0]
  path = segments[1..].join "/"
  if path.length > 0
    "atlas://#{host}/#{path}"
  else
    "atlas://#{host}"

getFullUrl = (node) ->
  formatUrl collectSegments node

resolveScopeUrl = (node, metaResolver) ->
  metaResolver.resolve getFullUrl node

recordScope = (node, scopes, metaResolver) ->
  if !node.bindings.size > 0
    return
  url = resolveScopeUrl node, metaResolver
  scopes[url] = toBindingsMap node.bindings

traverseScopes = (node, scopes, metaResolver) ->
  for child from node.children.values()
    recordScope child, scopes, metaResolver
    traverseScopes child, scopes, metaResolver
  return

buildScopes = (trie, metaResolver) ->
  scopes = {}
  traverseScopes trie, scopes, metaResolver
  scopes

Serialization =
  apply: (trie, keys) ->
    metaResolver = Resolvers.Registry.make keys
    imports: toBindingsMap trie.bindings
    scopes: buildScopes trie, metaResolver

export default Serialization