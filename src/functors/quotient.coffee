import ModuleGraph from "../categories/module-graph"
import ComponentGraph from "../categories/component-graph"

Quotient =
  apply: ( moduleGraph ) ->
    componentGraph = ComponentGraph.make()
    vertices = ModuleGraph.getVertices moduleGraph
    intraEdges = ModuleGraph.getIntraEdges moduleGraph
    interEdges = ModuleGraph.getInterEdges moduleGraph

    # Build undirected adjacency list for E_intra
    adj = new Map()
    for v from vertices
      adj.set v, []

    for edge in intraEdges
      adj.get(edge.source).push edge.target
      adj.get(edge.target).push edge.source

    visited = new Set()
    moduleToComponent = new Map()

    # 1. Edge Contraction: Identify Connected Components
    for startNode from vertices
      unless visited.has startNode
        componentModules = []
        queue = [ startNode ]
        visited.add startNode

        while queue.length > 0
          curr = queue.shift()
          componentModules.push curr
          
          for neighbor in adj.get curr
            unless visited.has neighbor
              visited.add neighbor
              queue.push neighbor

        # Deterministic component ID based on lexicographically first module
        componentModules.sort()
        componentId = "pkg:#{componentModules[0]}"
        
        for mod in componentModules
          moduleToComponent.set mod, componentId

        ComponentGraph.addComponent componentGraph, componentId, componentModules

    # 2. Map Inter-Component Edges
    seenEdges = new Set()

    for edge in interEdges
      sourceComp = moduleToComponent.get edge.source
      targetComp = moduleToComponent.get edge.target
      
      # Deduplicate edges with the same source, target, and label
      edgeKey = "#{sourceComp}::#{targetComp}::#{edge.label}"
      unless seenEdges.has edgeKey
        seenEdges.add edgeKey
        ComponentGraph.addEdge componentGraph,
          source: sourceComp
          target: targetComp
          label: edge.label

    componentGraph

export default Quotient
