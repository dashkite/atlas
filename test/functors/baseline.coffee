import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import { pipe } from "@dashkite/joy/function"
import ModuleGraph from "../../src/categories/module-graph"
import baseline from "../../src/functors/baseline"

Graph =
  addVertices: ( graph ) ->
    graph.addVertex "atlas://app/src/index.js"
    graph.addVertex "atlas://app/node_modules/maeve/index.js"
    graph.addVertex "atlas://app/src/helper.js"
    graph

  addInter: ( graph ) ->
    graph.addEdge
      source: "atlas://app/src/index.js"
      target: "atlas://app/node_modules/maeve/index.js"
      label: "maeve"
      type: "inter"
    graph

  addIntra: ( graph ) ->
    graph.addEdge
      source: "atlas://app/src/index.js"
      target: "atlas://app/src/helper.js"
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
  [ "app", "src", "index.js" ].reduce advanceSegment, root

verifyBindings = ( node ) ->
  assert.equal node.bindings.size, 1
  target = node.bindings.get "maeve"
  assert target?, "expected maeve binding"
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
