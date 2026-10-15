class Trie

  @make: ( segment = "", parent = null ) ->
    Object.assign ( new @ ),
      segment: segment
      parent: parent
      children: new Map()
      bindings: new Map()

  # Helper to walk down or create a path of segments
  upsertPath: ( segments ) ->
    node = @
    for segment in segments
      if !( node.children.has segment )
        node.children.set segment, ( Trie.make segment, node )
      node = node.children.get segment
    node

export default Trie