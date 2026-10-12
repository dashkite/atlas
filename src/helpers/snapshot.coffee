normalizePath = ( root, path ) ->
  if path.startsWith root
    "[ROOT]" + path.slice root.length
  else
    path

normalizeEdge = ( { source, target, label, type } ) ->
  { source, target, label, type }

serializeEdge = ( edge ) ->
  "#{edge.source}->#{edge.label}->#{edge.target}"

compareEdges = ( edgeA, edgeB ) ->
  ( serializeEdge edgeA ).localeCompare serializeEdge edgeB

normalizeGraph = ( graph ) ->
  vertices: ( Array.from graph.vertices ).sort()
  edges: ( graph.edges.map normalizeEdge ).sort compareEdges

normalizeTreeIndex = ( index ) ->
  result = {}
  for [ path, map ] from index.index
    # path is a comma separated path, like "pkg-A,pkg-B".
    result[ path ] = Object.fromEntries map
  result

export default
  normalizePath: normalizePath
  normalizeGraph: normalizeGraph
  normalizeTreeIndex: normalizeTreeIndex