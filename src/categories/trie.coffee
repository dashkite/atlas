Trie =
  make: (segment = "", parent = null) ->
    segment: segment
    parent: parent
    children: new Map()
    bindings: new Map()

  # Helper to walk down or create a path of segments
  upsertPath: (root, segments) ->
    node = root
    for segment in segments
      if !node.children.has segment
        node.children.set segment, ( Trie.make segment, node )
      node = node.children.get segment
    node

export default Trie