serializePath = ( path ) -> JSON.stringify path
deserializePath = ( key ) -> JSON.parse key

class TreeIndex
  @make: ->
    Object.assign ( new @ ),
      vertices: new Set()
      bindings: new Map() # Map<SerializedPath, Map<Label, TargetComponent>>

  addVertex: ( vertex ) ->
    @vertices.add vertex
    @

  getVertices: ->
    @vertices

  bind: ( path, label, target ) ->
    key = serializePath path
    if !@bindings.has key
      @bindings.set key, new Map()

    ( @bindings.get key ).set label, target
    @

  getBindings: ( path ) ->
    key = serializePath path
    ( @bindings.get key ) ? new Map()

  getPaths: ->
    ( Array.from @bindings.keys() ).map deserializePath

export default TreeIndex