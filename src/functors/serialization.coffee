import Resolvers from "../resolvers"

Serialization =
  apply: (trie, keys) ->
    metaResolver = Resolvers.Registry.make keys
    
    importMap =
      imports: {}
      scopes: {}

    # 1. Global imports (bindings on root)
    for [label, targetUrl] from trie.bindings
      importMap.imports[label] = targetUrl

    # Helper to reconstruct the abstract URL from the Trie path
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

    # 2. Scoped imports
    traverseScopes = (node) ->
      # If this descendant node has bindings, add them to a scope
      if node != trie && node.bindings.size > 0
        scopeAbstractUrl = getFullUrl node
        scopePhysicalUrl = metaResolver.resolve scopeAbstractUrl
        
        scopeMap = {}
        for [label, targetUrl] from node.bindings
          scopeMap[label] = targetUrl
          
        importMap.scopes[scopePhysicalUrl] = scopeMap
        
      for [segment, childNode] from node.children
        traverseScopes childNode
        
    traverseScopes trie
    importMap

export default Serialization
