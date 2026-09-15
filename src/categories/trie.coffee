Trie =
  make: (segment = "", parent = null) ->
    segment: segment
    parent: parent
    children: new Map()
    bindings: new Map()
    
  # Helper to walk down or create a path of segments
  upsertPath: (root, segments) ->
    currentNode = root
    for segment in segments
      unless currentNode.children.has segment
        currentNode.children.set segment, Trie.make(segment, currentNode)
      currentNode = currentNode.children.get segment
    currentNode

export default Trie
