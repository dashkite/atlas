import ModuleGraph from "../categories/module-graph"
import ComponentGraph from "../categories/component-graph"

groupVertex = ( moduleGraph, packageGroups, vertex ) ->
  packageId = ModuleGraph.getAttribute moduleGraph, vertex, "packageId"
  if !packageGroups.has packageId
    packageGroups.set packageId, []
  ( packageGroups.get packageId ).push vertex
  return

groupVertices = ( moduleGraph ) ->
  # 1. Edge Contraction: Equivalence Classes via packageId
  packageGroups = new Map()
  for vertex from ModuleGraph.getVertices moduleGraph
    groupVertex moduleGraph, packageGroups, vertex
  packageGroups

registerComponent = ( componentGraph, moduleToComponent, group ) ->
  [ packageId, modules ] = group
  modules.sort()
  # Deterministic component ID based on packageId
  componentId = packageId
  for module in modules
    moduleToComponent.set module, componentId
  ComponentGraph.addComponent componentGraph, componentId, modules
  return

registerComponents = ( componentGraph, packageGroups ) ->
  moduleToComponent = new Map()
  for group from packageGroups
    registerComponent componentGraph, moduleToComponent, group
  moduleToComponent

projectEdge = ( moduleToComponent, edge ) ->
  sourceComponent = moduleToComponent.get edge.source
  targetComponent = moduleToComponent.get edge.target
  source: sourceComponent
  target: targetComponent
  label: edge.label

addUniqueEdge = ( componentGraph, seenEdges, edge ) ->
  # Deduplicate edges with the same source, target, and label
  edgeKey = "#{edge.source}::#{edge.target}::#{edge.label}"
  if !seenEdges.has edgeKey
    seenEdges.add edgeKey
    ComponentGraph.addEdge componentGraph, edge
  return

projectEdges = ( componentGraph, moduleToComponent, interEdges ) ->
  # 2. Map Inter-Component Edges
  seenEdges = new Set()
  for edge in interEdges
    componentEdge = projectEdge moduleToComponent, edge
    addUniqueEdge componentGraph, seenEdges, componentEdge
  return

Quotient =
  apply: ( moduleGraph ) ->
    componentGraph = ComponentGraph.make()
    packageGroups = groupVertices moduleGraph
    moduleToComponent = registerComponents componentGraph, packageGroups
    interEdges = ModuleGraph.getInterEdges moduleGraph
    projectEdges componentGraph, moduleToComponent, interEdges
    componentGraph

export default Quotient