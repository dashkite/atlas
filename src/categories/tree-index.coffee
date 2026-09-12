serializePath = ( path ) -> JSON.stringify path
deserializePath = ( key ) -> JSON.parse key

TreeIndex =
  make: ->
    vertices: new Set()
    bindings: new Map() # Map<SerializedPath, Map<Label, TargetComponent>>

  addVertex: ( index, componentId ) ->
    index.vertices.add componentId
    index

  getVertices: ( index ) ->
    index.vertices

  bind: ( index, path, label, targetComponent ) ->
    key = serializePath path
    unless index.bindings.has key
      index.bindings.set key, new Map()
    
    index.bindings.get(key).set label, targetComponent
    index

  getBindings: ( index, path ) ->
    key = serializePath path
    index.bindings.get(key) ? new Map()

  getPaths: ( index ) ->
    Array.from(index.bindings.keys()).map deserializePath

export default TreeIndex
