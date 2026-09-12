import TreeIndex from "../categories/tree-index"
import ComponentGraph from "../categories/component-graph"
import Path from "../categories/path"

Compiler =
  apply: ( componentGraph, options = {} ) ->
    options.compact ?= true
    index = TreeIndex.make()
    edges = ComponentGraph.getEdges componentGraph
    vertices = ComponentGraph.getVertices componentGraph

    # 1. Calculate incoming and outgoing edges for each vertex
    inEdges = new Map()
    outEdges = new Map()
    for v from vertices
      inEdges.set v, []
      outEdges.set v, []

    for e in edges
      inEdges.get(e.target).push e
      outEdges.get(e.source).push e

    # 2. Identify Conflicted Labels (Collision Constraint)
    labelTargets = new Map()
    for e in edges
      unless labelTargets.has e.label
        labelTargets.set e.label, new Set()
      labelTargets.get(e.label).add e.target
      
    conflictedLabels = new Set()
    for [lbl, targets] from labelTargets
      if targets.size > 1
        conflictedLabels.add lbl

    # 3. Evaluate Topological Closure (canHoist)
    memoHoist = new Map()
    evaluateHoist = ( u ) ->
      return memoHoist.get(u) if memoHoist.has u
      
      # Constraint 1: Check incoming edges for label collisions
      for inE in inEdges.get(u)
        if conflictedLabels.has inE.label
          memoHoist.set u, false
          return false
          

      memoHoist.set u, true
      return true

    # 4. Find roots (in-degree 0)
    roots = []
    for v from vertices
      if inEdges.get(v).length == 0
        roots.push v

    # 5. Tree Embedding & Compaction
    queue = []
    for root in roots
      # Bind root component identifier at the root path
      TreeIndex.bind index, Path.root, root, root
      TreeIndex.addVertex index, root
      queue.push { component: root, path: Path.root }
      
    visited = new Set()

    while queue.length > 0
      { component, path } = queue.shift()
      
      visitKey = "#{component}::#{JSON.stringify(path)}"
      continue if visited.has visitKey
      visited.add visitKey

      for loopEdge in outEdges.get(component)
        target = loopEdge.target
        TreeIndex.addVertex index, target
        
        # Apply Edge Rebasing if compaction is enabled and closure constraints are met
        if options.compact && evaluateHoist(target)
          TreeIndex.bind index, Path.root, loopEdge.label, target
          queue.push { component: target, path: Path.root }
        else
          # Otherwise, embed at the baseline hierarchical path
          childPath = Path.concat path, component
          TreeIndex.bind index, childPath, loopEdge.label, target
          queue.push { component: target, path: childPath }

    index

export default Compiler
