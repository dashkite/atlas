serializePath = ( path ) -> JSON.stringify path
deserializePath = ( key ) -> JSON.parse key

TreeIndex =
  make: ->
    vertices: new Set()
    bindings: new Map() # Map<SerializedPath, Map<Label, TargetComponent>>

  addVertex: ( index, vertex ) ->
    index.vertices.add vertex
    index

  getVertices: ( index ) ->
    index.vertices

  bind: ( index, path, binding... ) ->
    [ label, target ] =
      if Array.isArray binding[ 0 ] then binding[ 0 ] else binding
    key = serializePath path
    if !index.bindings.has key
      index.bindings.set key, new Map()

    ( index.bindings.get key ).set label, target
    index

  getBindings: ( index, path ) ->
    key = serializePath path
    ( index.bindings.get key ) ? new Map()

  getPaths: ( index ) ->
    ( Array.from index.bindings.keys() ).map deserializePath

export default TreeIndex