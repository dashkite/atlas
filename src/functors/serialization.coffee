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

resolveScopeUrl = (node, resolver) ->
  resolver.resolve getFullUrl node

recordScope = (node, scopes, resolver) ->
  if !node.bindings.size > 0
    return
  url = resolveScopeUrl node, resolver
  scopes[url] = toBindingsMap node.bindings

traverseScopes = (node, scopes, resolver) ->
  for child from node.children.values()
    recordScope child, scopes, resolver
    traverseScopes child, scopes, resolver
  return

buildScopes = (trie, resolver) ->
  scopes = {}
  traverseScopes trie, scopes, resolver
  scopes

Serialization =
  apply: (trie, keys) ->
    resolver = Resolvers.Registry.make keys
    imports: toBindingsMap trie.bindings
    scopes: buildScopes trie, resolver

export default Serialization