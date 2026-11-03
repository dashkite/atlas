import TreeIndex from "../categories/tree-index"
import Path from "../categories/path"

buildEdgeIndex = ( graph, endpoint ) ->
  index = new Map()
  for vertex from graph.getVertices()
    index.set vertex, []
  for edge in graph.getEdges()
    ( index.get edge[ endpoint ]).push edge
  index

collectLabelTargets = ( edges ) ->
  targets = new Map()
  for edge in edges
    if !targets.has edge.label
      targets.set edge.label, new Set()
    ( targets.get edge.label ).add edge.target
  targets

findConflictedLabels = ( edges ) ->
  conflicted = new Set()
  for [ label, targets ] from collectLabelTargets edges
    if targets.size > 1
      conflicted.add label
  conflicted

hasCollision = ( vertex, incoming, conflicted ) ->
  ( incoming.get vertex ).some ( edge ) ->
    conflicted.has edge.label

findRoots = ( graph, incoming ) ->
  roots = []
  for vertex from graph.getVertices()
    if ( incoming.get vertex ).length == 0
      roots.push vertex
  roots

analyzeGraph = ( graph ) ->
  incoming: buildEdgeIndex graph, "target"
  outgoing: buildEdgeIndex graph, "source"
  conflicted: findConflictedLabels graph.getEdges()

defaults =
  compact: true

serializeItem = ( component, path ) ->
  "#{ component }::#{ JSON.stringify path }"

class TreeCompiler
  @make: ( graph, options = {}) ->
    options = { defaults..., options... }
    { incoming, outgoing, conflicted } = analyzeGraph graph
    Object.assign ( new @ ),
      compact: options.compact
      incoming: incoming
      outgoing: outgoing
      conflicted: conflicted
      index: TreeIndex.make()
      queue: []
      visited: new Set()
      cache: new Map()

  canHoist: ( target ) ->
    if @cache.has target
      @cache.get target
    else
      hoistable = !hasCollision target, @incoming, @conflicted
      @cache.set target, hoistable
      hoistable

  resolvePath: ( target, item ) ->
    if @compact && ( @canHoist target )
      Path.root
    else
      Path.concat item.path, item.component

  seedRoots: ( graph ) ->
    for root in findRoots graph, @incoming
      @index.bind Path.root, root, root
      @index.addVertex root
      @queue.push { component: root, path: Path.root }
    return

  embedEdge: ( edge, item ) ->
    target = edge.target
    destination = @resolvePath target, item
    @index.addVertex target
    @index.bind destination, edge.label, target
    @queue.push { component: target, path: destination }
    return

  processItem: ( item ) ->
    key = serializeItem item.component, item.path
    if !@visited.has key
      @visited.add key
      for edge in @outgoing.get item.component
        @embedEdge edge, item
    return

  compile: ( graph ) ->
    @seedRoots graph
    while @queue.length > 0
      item = @queue.shift()
      @processItem item
    @index

functor = ( graph, options = {}) ->
  ( TreeCompiler.make graph, options ).compile graph

export default functor