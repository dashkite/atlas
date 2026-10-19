import { pipe } from "@dashkite/joy"
import ComponentGraph from "../categories/component-graph"

groupVertex = ( graph, groups, vertex ) ->
  id = graph.getAttribute vertex, "packageId"
  if !groups.has id
    groups.set id, []
  ( groups.get id ).push vertex
  return

groupVertices = ( graph ) ->
  # 1. Edge Contraction: Equivalence Classes via packageId
  groups = new Map()
  for vertex from graph.getVertices()
    groupVertex graph, groups, vertex
  groups

registerComponent = ( graph, components, group ) ->
  [ id, modules ] = group
  modules.sort()
  # Deterministic component ID based on packageId
  for module in modules
    components.set module, id
  graph.addComponent id, modules
  return

projectEdge = ( components, edge ) ->
  source: components.get edge.source
  target: components.get edge.target
  label: edge.label

addUniqueEdge = ( graph, seen, edge ) ->
  # Deduplicate edges with the same source, target, and label
  key = "#{edge.source}::#{edge.target}::#{edge.label}"
  if !seen.has key
    seen.add key
    graph.addEdge edge
  return

createContext = ( input ) ->
  input: input
  output: ComponentGraph.make()

registerComponents = ( context ) ->
  components = new Map()
  for group from groupVertices context.input
    registerComponent context.output, components, group
  { context..., components }

projectEdges = ( context ) ->
  # 2. Map Inter-Component Edges
  seen = new Set()
  for edge in context.input.getInterEdges()
    addUniqueEdge context.output, seen, projectEdge context.components, edge
  context.output

functor = pipe [
  createContext
  registerComponents
  projectEdges
]

export default functor