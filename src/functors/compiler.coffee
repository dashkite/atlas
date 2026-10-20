import { pipe } from "@dashkite/joy"
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

findRoots = ( graph, incoming ) ->
  roots = []
  for vertex from graph.getVertices()
    if ( incoming.get vertex ).length == 0
      roots.push vertex
  roots

createQueueItem = ( component, path ) ->
  { component, path }

initializeQueue = ( index, roots ) ->
  queue = []
  for root in roots
    index.bind Path.root, root, root
    index.addVertex root
    queue.push createQueueItem root, Path.root
  queue

analyzeGraph = ( graph ) ->
  incoming: buildEdgeIndex graph, "target"
  outgoing: buildEdgeIndex graph, "source"
  conflicted: findConflictedLabels graph.getEdges()

initializeState = ( graph, incoming ) ->
  index = TreeIndex.make()
  {
    index: index
    queue: initializeQueue index, ( findRoots graph, incoming )
    visited: new Set()
    cache: new Map()
  }

DEFAULTS =
  compact: true

createContext = ( graph, options = {}) ->
  options = { DEFAULTS..., options... }
  analysis = analyzeGraph graph
  {
    analysis...
    ( initializeState graph, analysis.incoming )...
    compact: options.compact
  }

resolvePath = ( target, item, context ) ->
  if context.compact && ( canHoist target, context )
    Path.root
  else
    Path.concat item.path, item.component

embedEdge = ( context, edge, item ) ->
  target = edge.target
  destination = resolvePath target, item, context
  context.index.addVertex target
  context.index.bind destination, edge.label, target
  context.queue.push createQueueItem target, destination
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
  context.index

functor = pipe [
  createContext
  embedTree
]

export default functor