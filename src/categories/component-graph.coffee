ComponentGraph =
  make: ->
    vertices: new Set()
    edges: []
    componentModules: new Map()

  getVertices: ( graph ) ->
    graph.vertices

  getEdges: ( graph ) ->
    graph.edges

  addComponent: ( graph, componentId, modules ) ->
    graph.vertices.add componentId
    graph.componentModules.set componentId, new Set modules
    graph

  getModules: ( graph, componentId ) ->
    graph.componentModules.get componentId

  addEdge: ( graph, edge ) ->
    graph.edges.push edge
    graph

export default ComponentGraph
