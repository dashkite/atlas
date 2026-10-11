isNotEmpty = ( segment ) -> segment.length > 0

extractSuffix = ( label, prefix ) ->
  suffix = label.substring prefix.length
  ( suffix.split "/" ).filter isNotEmpty

findAncestor = ( target, suffixSegments ) ->
  current = target
  for segment in suffixSegments by -1
    if current.segment != segment
      return null
    current = current.parent
  current

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
  group = []
  candidate = matches[ 0 ].ancestor
  for match in matches
    if match.ancestor != candidate
      return null
    group.push match.label
  { group, candidate }

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
      prefixes.push ( ( parts.slice 0, i ).join "/" ) + "/"
  prefixes

collectPrefixes = ( bindings ) ->
  prefixes = new Set()
  for [ label ] from bindings
    for prefix in generatePrefixes label
      prefixes.add prefix
  ( Array.from prefixes ).sort ( a, b ) -> b.length - a.length

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

Compression =
  apply: ( trie ) ->
    Compression.compress trie
    trie

  compress: ( node ) ->
    for childNode from node.children.values()
      Compression.compress childNode
    compressNode node
    return

export default Compression