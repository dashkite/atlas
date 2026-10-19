promoteBinding = ( node, parent, [ label, target ] ) ->
  if !parent.bindings.has label
    parent.bindings.set label, target
    node.bindings.delete label
  else if ( parent.bindings.get label ) == target
    node.bindings.delete label
  return

promoteBindings = ( node, parent ) ->
  if parent?
    for entry from Array.from node.bindings.entries()
      promoteBinding node, parent, entry
  return

compact = ( node, parent ) ->
  # Post-order traversal: visit children first
  for child from node.children.values()
    compact child, node

  promoteBindings node, parent
  return

functor = ( trie ) ->
  compact trie, null
  trie

export default functor