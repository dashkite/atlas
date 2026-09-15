import ModuleGraph from "../categories/module-graph"
import ComponentGraph from "../categories/component-graph"

Quotient =
  apply: ( moduleGraph ) ->
    componentGraph = ComponentGraph.make()
    vertices = ModuleGraph.getVertices moduleGraph
    intraEdges = ModuleGraph.getIntraEdges moduleGraph
    interEdges = ModuleGraph.getInterEdges moduleGraph

    # 1. Edge Contraction: Equivalence Classes via packageId
    packageGroups = new Map()
    for v from vertices
      # Fallback to the vertex URL itself if no packageId attribute is present
      pkgId = (ModuleGraph.getAttribute moduleGraph, v, "packageId") ? v
      
      unless packageGroups.has pkgId
        packageGroups.set pkgId, []
      packageGroups.get(pkgId).push v

    moduleToComponent = new Map()
    for [pkgId, modules] from packageGroups
      modules.sort()
      # Deterministic component ID based on packageId
      componentId = pkgId
      
      for mod in modules
        moduleToComponent.set mod, componentId
        
      ComponentGraph.addComponent componentGraph, componentId, modules

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
