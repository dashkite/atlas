isNotEmpty = ( segment ) -> segment.length > 0

extractSuffix = ( label, prefix ) ->
  suffix = label.substring prefix.length
  ( suffix.split "/" ).filter isNotEmpty

stepAncestor = ( current, segment ) ->
  if ( current? ) && ( current.segment == segment )
    current.parent
  else
    null

findAncestor = ( node, segments ) ->
  [ segments... ]
    .reverse()
    .reduce stepAncestor, node

matchBinding = ( label, target, prefix ) ->
  if label.startsWith prefix
    ancestor = findAncestor target, ( extractSuffix label, prefix )
    if ancestor?
      { label, ancestor }
    else
      null
  else
    null

findMatches = ( bindings, prefix ) ->
  matches = []
  for [ label, target ] from bindings
    match = matchBinding label, target, prefix
    if match?
      matches.push match
  matches

resolveGroup = ( matches ) ->
  candidate = matches[ 0 ].ancestor
  if matches.every ( match ) -> match.ancestor == candidate
    group: matches.map ( match ) -> match.label
    candidate: candidate
  else
    null

evaluatePrefix = ( node, prefix ) ->
  matches = findMatches node.bindings, prefix
  if matches.length > 1
    resolveGroup matches
  else
    null

generatePrefixes = ( label ) ->
  parts = label.split "/"
  limit = if label.endsWith "/" then parts.length - 2 else parts.length - 1
  prefixes = []
  if limit >= 1
    for i in [ 1..limit ] by 1
      prefixes.push (( parts.slice 0, i ).join "/" ) + "/"
  prefixes

collectPrefixes = ( bindings ) ->
  prefixes = new Set()
  for [ label ] from bindings
    for prefix in generatePrefixes label
      prefixes.add prefix
  ( Array.from prefixes ).sort ( first, second ) ->
    second.length - first.length

replaceBindings = ( node, prefix, result ) ->
  for label in result.group
    node.bindings.delete label
  node.bindings.set prefix, result.candidate
  return

compressPrefix = ( node, prefix ) ->
  result = evaluatePrefix node, prefix
  if result?
    replaceBindings node, prefix, result
  return

compressNode = ( node ) ->
  for prefix in collectPrefixes node.bindings
    compressPrefix node, prefix
  return

compress = ( node ) ->
  for child from node.children.values()
    compress child
  compressNode node
  return

functor = ( trie ) ->
  compress trie
  trie

export default functor