normalizePath = ( rootDirectory, absolutePath ) ->
  if absolutePath.startsWith rootDirectory
    "[ROOT]" + absolutePath.slice rootDirectory.length
  else
    absolutePath

compareEdges = ( edgeA, edgeB ) ->
  serializedEdgeA = "#{edgeA.source}->#{edgeA.label}->#{edgeA.target}"
  serializedEdgeB = "#{edgeB.source}->#{edgeB.label}->#{edgeB.target}"
  serializedEdgeA.localeCompare serializedEdgeB

normalizeGraph = ( graph ) ->
  normalizedGraph =
    vertices: ( Array.from graph.vertices ).sort()
    edges: graph.edges.map ( { source, target, label, type } ) ->
      { source, target, label, type }
  # Sort edges deterministically
  normalizedGraph.edges.sort compareEdges
  normalizedGraph

normalizeTreeIndex = ( index ) ->
  normalizedTreeIndex = {}
  for [ pathKey, map ] from index.index
    # pathKey is a comma separated path, like "pkg-A,pkg-B".
    normalizedTreeIndex[ pathKey ] = Object.fromEntries map
  normalizedTreeIndex

export default ( rootDirectory ) ->
  normalizePath: ( absolutePath ) ->
    normalizePath rootDirectory, absolutePath
  normalizeGraph: normalizeGraph
  normalizeTreeIndex: normalizeTreeIndex