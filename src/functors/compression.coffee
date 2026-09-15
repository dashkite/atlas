import Trie from "../categories/trie"

Compression =
  apply: (trie) ->
    Compression.compress trie
    trie

  compress: (node) ->
    for [segment, childNode] from node.children
      Compression.compress childNode

    prefixes = new Set()
    for [label, target] from node.bindings.entries()
      parts = label.split("/")
      limit = if label.endsWith("/") then parts.length - 2 else parts.length - 1
      if limit >= 1
        for i in [1..limit] by 1
          prefix = parts.slice(0, i).join("/") + "/"
          prefixes.add prefix

    sortedPrefixes = Array.from(prefixes).sort (a, b) -> b.length - a.length

    for prefix in sortedPrefixes
      group = []
      contradiction = false
      candidateN = null
      
      for [label, target] from node.bindings.entries()
        if label.startsWith prefix
          suffix = label.substring prefix.length
          suffixSegments = suffix.split("/").filter (s) -> s.length > 0
          
          current = target
          for i in [0...suffixSegments.length] by 1
            current = current?.parent
            
          if not current?
            contradiction = true
            break
            
          if not candidateN?
            candidateN = current
          else if candidateN != current
            contradiction = true
            break
            
          group.push label

      if group.length > 1 and not contradiction
        for label in group
          node.bindings.delete label
        node.bindings.set prefix, candidateN

export default Compression
