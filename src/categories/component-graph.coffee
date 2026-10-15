class ComponentGraph
  @make: ->
    Object.assign ( new @ ),
      vertices: new Set()
      edges: []
      modules: new Map()

  getVertices: ->
    @vertices

  getEdges: ->
    @edges

  addComponent: ( identifier, modules ) ->
    @vertices.add identifier
    @modules.set identifier, new Set modules
    @

  getModules: ( identifier ) ->
    @modules.get identifier

  addEdge: ( edge ) ->
    @edges.push edge
    @

export default ComponentGraph
