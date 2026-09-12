import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"

export default ->
  [
    test "creates an empty graph", ->
      graph = ModuleGraph.make()
      assert ModuleGraph.getVertices(graph).size == 0
      assert ModuleGraph.getEdges(graph).length == 0

    test "adds vertices", ->
      graph = ModuleGraph.make()
      ModuleGraph.addVertex graph, "file:///app/index.js"
      
      vertices = ModuleGraph.getVertices graph
      assert.equal vertices.size, 1
      assert vertices.has "file:///app/index.js"

    test "adds and partitions morphisms", ->
      graph = ModuleGraph.make()
      ModuleGraph.addVertex graph, "file:///app/index.js"
      ModuleGraph.addVertex graph, "file:///app/helper.js"
      ModuleGraph.addVertex graph, "file:///node_modules/maeve/index.js"

      # Add an intra-component morphism
      ModuleGraph.addEdge graph,
        source: "file:///app/index.js"
        target: "file:///app/helper.js"
        label: "./helper.js"
        type: "intra"

      # Add an inter-component morphism
      ModuleGraph.addEdge graph,
        source: "file:///app/index.js"
        target: "file:///node_modules/maeve/index.js"
        label: "maeve"
        type: "inter"

      edges = ModuleGraph.getEdges graph
      assert.equal edges.length, 2

      intra = ModuleGraph.getIntraEdges graph
      assert.equal intra.length, 1
      assert.equal intra[ 0 ].label, "./helper.js"
      assert.equal intra[ 0 ].source, "file:///app/index.js"
      assert.equal intra[ 0 ].target, "file:///app/helper.js"

      inter = ModuleGraph.getInterEdges graph
      assert.equal inter.length, 1
      assert.equal inter[ 0 ].label, "maeve"
      assert.equal inter[ 0 ].source, "file:///app/index.js"
      assert.equal inter[ 0 ].target, "file:///node_modules/maeve/index.js"
  ]

