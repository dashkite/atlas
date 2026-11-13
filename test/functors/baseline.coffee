import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import { pipe } from "@dashkite/joy/function"
import ModuleGraph from "../../src/categories/module-graph"
import baseline from "../../src/functors/baseline"

Vertices =
  index: "atlas://application/src/index.js"
  helper: "atlas://application/src/helper.js"
  maeve: "atlas://node/maeve@1.0.0/index.js"

Packages =
  application: "atlas://application"
  maeve: "atlas://node/maeve@1.0.0"

addModule = ( graph, vertex, id ) ->
  graph.addVertex vertex
  graph.setAttribute vertex, "packageId", id

Graph =
  addVertices: ( graph ) ->
    addModule graph, Vertices.index, Packages.application
    addModule graph, Vertices.maeve, Packages.maeve
    addModule graph, Vertices.helper, Packages.application
    graph

  addInter: ( graph ) ->
    graph.addEdge
      source: Vertices.index
      target: Vertices.maeve
      label: "maeve"
      type: "inter"
    graph

  addIntra: ( graph ) ->
    graph.addEdge
      source: Vertices.index
      target: Vertices.helper
      label: "./helper.js"
      type: "intra"
    graph

Graph.build = pipe [
  ( -> ModuleGraph.make() )
  Graph.addVertices
  Graph.addInter
  Graph.addIntra
]

advanceSegment = ( node, segment ) ->
  next = node.children.get segment
  assert next?
  next

getNode = ( root ) ->
  [ "application", "src", "index.js" ].reduce advanceSegment, root

verifyBindings = ( node ) ->
  assert.equal node.bindings.size, 1
  target = node.bindings.get "maeve"
  assert target?
  assert.equal target.segment, "index.js"
  assert !node.bindings.has "./helper.js"

verifyTrie = pipe [
  getNode
  verifyBindings
]

testBaseline = pipe [
  Graph.build
  baseline
  verifyTrie
]

export default ->
  [
    test "creates exact, module-scoped baseline mappings", testBaseline
  ]
