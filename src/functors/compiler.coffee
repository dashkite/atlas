import TreeIndex from "../categories/tree-index"
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
  for edge in incoming.get vertex
    if conflicted.has edge.label
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

class QueueItem
  @make: ( component, path ) ->
    Object.assign ( new @ ),
      component: component
      path: path

initializeQueue = ( index, roots ) ->
  queue = []
  for root in roots
    index.bind Path.root, [ root, root ]
    index.addVertex root
    queue.push QueueItem.make root, Path.root
  queue

class TraversalContext
  @make: ( vertices, edges, compact ) ->
    incoming = buildEdgeIndex vertices, edges, "target"
    outgoing = buildEdgeIndex vertices, edges, "source"
    index = TreeIndex.make()
    Object.assign ( new @ ),
      index: index
      incoming: incoming
      outgoing: outgoing
      conflicted: findConflictedLabels edges
      queue: initializeQueue index, ( findRoots vertices, incoming )
      compact: compact
      visited: new Set()
      cache: new Map()

resolvePath = ( target, item, context ) ->
  if context.compact && ( canHoist target, context )
    Path.root
  else
    Path.concat item.path, item.component

embedEdge = ( context, edge, item ) ->
  target = edge.target
  destination = resolvePath target, item, context
  context.index.addVertex target
  context.index.bind destination, [ edge.label, target ]
  context.queue.push QueueItem.make target, destination
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
  apply: ( graph, compact = true ) ->
    edges = graph.getEdges()
    vertices = graph.getVertices()
    context = TraversalContext.make vertices, edges, compact
    embedTree context
    context.index

export default Compiler