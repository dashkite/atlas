ModuleGraph =
  make: ->
    vertices: new Set()
    edges: []

  getVertices: ( graph ) ->
    graph.vertices

  getEdges: ( graph ) ->
    graph.edges

  addVertex: ( graph, vertex ) ->
    graph.vertices.add vertex
    graph

  addEdge: ( graph, edge ) ->
    graph.edges.push edge
    graph

  getIntraEdges: ( graph ) ->
    graph.edges.filter ( edge ) -> edge.type == "intra"

  getInterEdges: ( graph ) ->
    graph.edges.filter ( edge ) -> edge.type == "inter"

export default ModuleGraph
