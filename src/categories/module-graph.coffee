ModuleGraph =
  make: ->
    vertices: new Set()
    edges: []
    attributes: new Map()

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

  setAttribute: ( graph, vertex, key, value ) ->
    unless graph.attributes.has vertex
      graph.attributes.set vertex, new Map()
    graph.attributes.get(vertex).set key, value
    graph

  getAttribute: ( graph, vertex, key ) ->
    graph.attributes.get(vertex)?.get key

export default ModuleGraph
