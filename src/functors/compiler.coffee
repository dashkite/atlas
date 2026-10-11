import TreeIndex from "../categories/tree-index"
import ComponentGraph from "../categories/component-graph"
import Path from "../categories/path"

buildEdgeIndex = ( vertices, edges, endpoint ) ->
  index = new Map()
  for vertex from vertices
    index.set vertex, []
  for edge in edges
    ( index.get edge[ endpoint ] ).push edge
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
  for incomingEdge in incoming.get vertex
    if conflicted.has incomingEdge.label
      return true
  false

canHoist = ( target, context ) ->
  if context.cache.has target
    context.cache.get target
  else
    hoistable = !hasCollision target, context.incoming, context.conflicted
    context.cache.set target, hoistable
    hoistable

findRoots = ( vertices, incoming ) ->
  roots = []
  for vertex from vertices
    if ( incoming.get vertex ).length == 0
      roots.push vertex
  roots

initializeQueue = ( index, roots ) ->
  queue = []
  for root in roots
    TreeIndex.bind index, Path.root, root, root
    TreeIndex.addVertex index, root
    queue.push { component: root, path: Path.root }
  queue

createContext = ( vertices, edges, compact ) ->
  incoming = buildEdgeIndex vertices, edges, "target"
  outgoing = buildEdgeIndex vertices, edges, "source"
  index = TreeIndex.make()
  queue = initializeQueue index, ( findRoots vertices, incoming )
  conflicted = findConflictedLabels edges
  visited = new Set()
  cache = new Map()
  { index, incoming, outgoing, conflicted, queue, compact, visited, cache }

resolvePath = ( target, item, context ) ->
  if context.compact && ( canHoist target, context )
    Path.root
  else
    Path.concat item.path, item.component

embedEdge = ( context, edge, item ) ->
  target = edge.target
  destination = resolvePath target, item, context
  TreeIndex.addVertex context.index, target
  TreeIndex.bind context.index, destination, edge.label, target
  context.queue.push { component: target, path: destination }
  return

processItem = ( item, context ) ->
  key = "#{ item.component }::#{ JSON.stringify item.path }"
  if !context.visited.has key
    context.visited.add key
    for edge in context.outgoing.get item.component
      embedEdge context, edge, item
  return

embedTree = ( context ) ->
  while context.queue.length > 0
    item = context.queue.shift()
    processItem item, context
  return

Compiler =
  apply: ( componentGraph, options = {} ) ->
    options.compact ?= true
    edges = ComponentGraph.getEdges componentGraph
    vertices = ComponentGraph.getVertices componentGraph
    context = createContext vertices, edges, options.compact
    embedTree context
    context.index

export default Compiler