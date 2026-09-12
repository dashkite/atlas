import Path from "node:path"

export default ( cwd ) ->
  normalizePath: ( absPath ) ->
    if absPath.startsWith cwd
      "[ROOT]" + absPath.slice(cwd.length)
    else
      absPath
      
  normalizeGraph: ( graph ) ->
    norm =
      vertices: Array.from(graph.vertices).sort()
      edges: graph.edges.map (e) -> { source: e.source, target: e.target, label: e.label, type: e.type }
    # Sort edges deterministically
    norm.edges.sort (a, b) ->
      strA = "#{a.source}->#{a.label}->#{a.target}"
      strB = "#{b.source}->#{b.label}->#{b.target}"
      strA.localeCompare strB
    norm

  normalizeTreeIndex: ( index ) ->
    norm = {}
    for [pathKey, map] from index.index
      # pathKey is a comma separated path, like "pkg-A,pkg-B".
      norm[pathKey] = Object.fromEntries(map)
    norm
