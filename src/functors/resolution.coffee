import Trie from "../categories/trie"
import Resolvers from "../resolvers"

Resolution =
  apply: (trie, keys) ->
    metaResolver = Resolvers.Registry.make keys
    
    getFullUrl = (node) ->
      segments = []
      current = node
      while current?.parent?
        segments.unshift current.segment
        current = current.parent
      return "" if segments.length == 0
      
      host = segments[0]
      path = segments[1..].join("/")
      
      if path.length > 0
        "atlas://#{host}/#{path}"
      else
        "atlas://#{host}"

    traverse = (node) ->
      for [label, target] from node.bindings
        targetUrl = getFullUrl target
        mappedString = metaResolver.resolve targetUrl
        node.bindings.set label, mappedString
        
      for [segment, childNode] from node.children
        traverse childNode
        
    traverse trie
    trie

export default Resolution
