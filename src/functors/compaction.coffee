import Trie from "../categories/trie"

Compaction =
  apply: (trie) ->
    Compaction.compact trie, null
    trie

  compact: (node, parent) ->
    # Post-order traversal: visit children first
    for [segment, childNode] from node.children
      Compaction.compact childNode, node

    # Attempt to lift bindings to parent
    # We must not hoist bindings out of a package boundary,
    # as that would render the URL meaningless (e.g. hoisting to resolver root)
    if parent? and not node.isPackage
      for [label, target] from Array.from(node.bindings.entries())
        if not parent.bindings.has label
          # Parent doesn't have it, lift it
          parent.bindings.set label, target
          node.bindings.delete label
        else if parent.bindings.get(label) == target
          # Parent has exact same mapping, lift succeeds (deduplicate)
          node.bindings.delete label
        # else: collision, target is different. Leave binding trapped in child.

export default Compaction
