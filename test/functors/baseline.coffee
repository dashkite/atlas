import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import { pipe } from "@dashkite/joy/function"
import ModuleGraph from "../../src/categories/module-graph"
import baseline from "../../src/functors/baseline"

addVertices = ( graph ) ->
  graph.addVertex "atlas://app/src/index.js"
  graph.addVertex "atlas://app/node_modules/maeve/index.js"
  graph.addVertex "atlas://app/src/helper.js"
  graph

addInterEdge = ( graph ) ->
  graph.addEdge
    source: "atlas://app/src/index.js"
    target: "atlas://app/node_modules/maeve/index.js"
    label: "maeve"
    type: "inter"
  graph

addIntraEdge = ( graph ) ->
  graph.addEdge
    source: "atlas://app/src/index.js"
    target: "atlas://app/src/helper.js"
    label: "./helper.js"
    type: "intra"
  graph

buildFixtureGraph = pipe [
  ( -> ModuleGraph.make() )
  addVertices
  addInterEdge
  addIntraEdge
]

advanceSegment = ( node, segment ) ->
  next = node.children.get segment
  assert next?
  next

getIndexNode = ( root ) ->
  [ "app", "src", "index.js" ].reduce advanceSegment, root

verifyBindings = ( node ) ->
  assert.equal node.bindings.size, 1
  target = node.bindings.get "maeve"
  assert target?, "expected maeve binding"
  assert.equal target.segment, "index.js"
  assert !node.bindings.has "./helper.js"

verifyTrie = pipe [
  getIndexNode
  verifyBindings
]

testBaseline = pipe [
  buildFixtureGraph
  baseline
  verifyTrie
]

export default ->
  [
    test "creates exact, module-scoped baseline mappings", testBaseline
  ]