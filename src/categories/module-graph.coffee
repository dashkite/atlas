class ModuleGraph
  @make: ->
    Object.assign ( new @ ),
      vertices: new Set()
      edges: []
      attributes: new Map()
      sources: new Map()

  getVertices: ->
    @vertices

  getEdges: ->
    @edges

  addVertex: ( vertex ) ->
    @vertices.add vertex
    @

  addEdge: ( edge ) ->
    @edges.push edge
    @

  getIntraEdges: ->
    @edges.filter ( edge ) -> edge.type == "intra"

  getInterEdges: ->
    @edges.filter ( edge ) -> edge.type == "inter"

  setAttribute: ( vertex, key, value ) ->
    if !@attributes.has vertex
      @attributes.set vertex, new Map()
    ( @attributes.get vertex ).set key, value
    @

  getAttribute: ( vertex, key ) ->
    ( @attributes.get vertex )?.get key

  setSource: ( vertex, source ) ->
    @sources.set vertex, source
    @

  getSource: ( vertex ) ->
    @sources.get vertex

export default ModuleGraph