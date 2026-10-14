import ModuleGraph from "../categories/module-graph"
import ComponentGraph from "../categories/component-graph"

groupVertex = ( graph, groups, vertex ) ->
  id = ModuleGraph.getAttribute graph, vertex, "packageId"
  if !groups.has id
    groups.set id, []
  ( groups.get id ).push vertex
  return

groupVertices = ( graph ) ->
  # 1. Edge Contraction: Equivalence Classes via packageId
  groups = new Map()
  for vertex from ModuleGraph.getVertices graph
    groupVertex graph, groups, vertex
  groups

registerComponent = ( graph, components, group ) ->
  [ id, modules ] = group
  modules.sort()
  # Deterministic component ID based on packageId
  for module in modules
    components.set module, id
  ComponentGraph.addComponent graph, id, modules
  return

registerComponents = ( graph, groups ) ->
  components = new Map()
  for group from groups
    registerComponent graph, components, group
  components

projectEdge = ( components, edge ) ->
  source: components.get edge.source
  target: components.get edge.target
  label: edge.label

addUniqueEdge = ( graph, seen, edge ) ->
  # Deduplicate edges with the same source, target, and label
  key = "#{edge.source}::#{edge.target}::#{edge.label}"
  if !seen.has key
    seen.add key
    ComponentGraph.addEdge graph, edge
  return

projectEdges = ( graph, components, edges ) ->
  # 2. Map Inter-Component Edges
  seen = new Set()
  for edge in edges
    projected = projectEdge components, edge
    addUniqueEdge graph, seen, projected
  return

Quotient =
  apply: ( input ) ->
    output = ComponentGraph.make()
    groups = groupVertices input
    components = registerComponents output, groups
    edges = ModuleGraph.getInterEdges input
    projectEdges output, components, edges
    output

export default Quotient