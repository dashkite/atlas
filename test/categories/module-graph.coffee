import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"

INTRA_EDGE =
  source: "file:///app/index.js"
  target: "file:///app/helper.js"
  label: "./helper.js"
  type: "intra"

INTER_EDGE =
  source: "file:///app/index.js"
  target: "file:///node_modules/maeve/index.js"
  label: "maeve"
  type: "inter"

buildGraph = ->
  graph = ModuleGraph.make()
  graph.addVertex "file:///app/index.js"
  graph.addVertex "file:///app/helper.js"
  graph.addVertex "file:///node_modules/maeve/index.js"
  graph.addEdge INTRA_EDGE
  graph.addEdge INTER_EDGE
  graph

export default ->
  [
    test "creates an empty graph", ->
      graph = ModuleGraph.make()
      assert graph.getVertices().size == 0
      assert graph.getEdges().length == 0

    test "adds vertices", ->
      graph = ModuleGraph.make()
      graph.addVertex "file:///app/index.js"

      vertices = graph.getVertices()
      assert.equal vertices.size, 1
      assert vertices.has "file:///app/index.js"

    test "adds morphisms", ->
      graph = buildGraph()
      assert.equal graph.getEdges().length, 2

    test "partitions intra-component morphisms", ->
      edges = buildGraph().getIntraEdges()
      assert.equal edges.length, 1
      assert.equal edges[ 0 ].label, "./helper.js"
      assert.equal edges[ 0 ].source, "file:///app/index.js"
      assert.equal edges[ 0 ].target, "file:///app/helper.js"

    test "partitions inter-component morphisms", ->
      edges = buildGraph().getInterEdges()
      assert.equal edges.length, 1
      assert.equal edges[ 0 ].label, "maeve"
      assert.equal edges[ 0 ].source, "file:///app/index.js"
      assert.equal edges[ 0 ].target, "file:///node_modules/maeve/index.js"
  ]