import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"
import baseline from "../../src/functors/baseline"

Vertices =
  index: "atlas://application/src/index.js"
  helper: "atlas://application/src/helper.js"
  maeve: "atlas://node/maeve@1.0.0/index.js"

Packages =
  application: "atlas://application"
  maeve: "atlas://node/maeve@1.0.0"

Edges =
  inter:
    source: Vertices.index
    target: Vertices.maeve
    label: "maeve"
    type: "inter"
  intra:
    source: Vertices.index
    target: Vertices.helper
    label: "./helper.js"
    type: "intra"

addModule = ( graph, vertex, id ) ->
  graph.addVertex vertex
  graph.setAttribute vertex, "packageId", id

buildGraph = ->
  graph = ModuleGraph.make()
  addModule graph, Vertices.index, Packages.application
  addModule graph, Vertices.maeve, Packages.maeve
  addModule graph, Vertices.helper, Packages.application
  graph.addEdge Edges.inter
  graph.addEdge Edges.intra
  graph

getNode = ( root ) ->
  node = root
  for segment in [ "application", "src", "index.js" ]
    node = node.children.get segment
    assert node?
  node

verifyBindings = ( node ) ->
  assert.equal node.bindings.size, 1
  target = node.bindings.get "maeve"
  assert target?
  assert.equal target.segment, "index.js"
  assert !node.bindings.has "./helper.js"

export default ->
  [
    test "creates exact, module-scoped baseline mappings", ->
      root = baseline buildGraph()
      verifyBindings getNode root
  ]
