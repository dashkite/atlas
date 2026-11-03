import ComponentGraph from "../categories/component-graph"

groupVertex = ( graph, groups, vertex ) ->
  id = graph.getAttribute vertex, "packageId"
  if !groups.has id
    groups.set id, []
  ( groups.get id ).push vertex
  return

groupVertices = ( graph ) ->
  groups = new Map()
  for vertex from graph.getVertices()
    groupVertex graph, groups, vertex
  groups

registerComponent = ( graph, components, group ) ->
  [ id, modules ] = group
  modules.sort()
  for module in modules
    components.set module, id
  graph.addComponent id, modules
  return

projectEdge = ( components, edge ) ->
  source: components.get edge.source
  target: components.get edge.target
  label: edge.label

addUniqueEdge = ( graph, seen, edge ) ->
  key = "#{edge.source}::#{edge.target}::#{edge.label}"
  if !seen.has key
    seen.add key
    graph.addEdge edge
  return

registerComponents = ( input, output ) ->
  components = new Map()
  for group from groupVertices input
    registerComponent output, components, group
  components

projectEdges = ( input, output, components ) ->
  seen = new Set()
  for edge in input.getInterEdges()
    addUniqueEdge output, seen, projectEdge components, edge
  output

functor = ( input ) ->
  output = ComponentGraph.make()
  components = registerComponents input, output
  projectEdges input, output, components

export default functor