ComponentGraph =
  make: ->
    vertices: new Set()
    edges: []
    modules: new Map()

  getVertices: ( graph ) ->
    graph.vertices

  getEdges: ( graph ) ->
    graph.edges

  addComponent: ( graph, identifier, modules ) ->
    graph.vertices.add identifier
    graph.modules.set identifier, new Set modules
    graph

  getModules: ( graph, identifier ) ->
    graph.modules.get identifier

  addEdge: ( graph, edge ) ->
    graph.edges.push edge
    graph

export default ComponentGraph
