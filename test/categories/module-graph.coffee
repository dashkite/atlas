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
  ModuleGraph.addVertex graph, "file:///app/index.js"
  ModuleGraph.addVertex graph, "file:///app/helper.js"
  ModuleGraph.addVertex graph, "file:///node_modules/maeve/index.js"
  ModuleGraph.addEdge graph, INTRA_EDGE
  ModuleGraph.addEdge graph, INTER_EDGE
  graph

export default ->
  [
    test "creates an empty graph", ->
      graph = ModuleGraph.make()
      assert ( ModuleGraph.getVertices graph ).size == 0
      assert ( ModuleGraph.getEdges graph ).length == 0

    test "adds vertices", ->
      graph = ModuleGraph.make()
      ModuleGraph.addVertex graph, "file:///app/index.js"

      vertices = ModuleGraph.getVertices graph
      assert.equal vertices.size, 1
      assert vertices.has "file:///app/index.js"

    test "adds morphisms", ->
      graph = buildGraph()
      assert.equal ( ModuleGraph.getEdges graph ).length, 2

    test "partitions intra-component morphisms", ->
      edges = ModuleGraph.getIntraEdges buildGraph()
      assert.equal edges.length, 1
      assert.equal edges[ 0 ].label, "./helper.js"
      assert.equal edges[ 0 ].source, "file:///app/index.js"
      assert.equal edges[ 0 ].target, "file:///app/helper.js"

    test "partitions inter-component morphisms", ->
      edges = ModuleGraph.getInterEdges buildGraph()
      assert.equal edges.length, 1
      assert.equal edges[ 0 ].label, "maeve"
      assert.equal edges[ 0 ].source, "file:///app/index.js"
      assert.equal edges[ 0 ].target, "file:///node_modules/maeve/index.js"
  ]