import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ComponentGraph from "../../src/categories/component-graph"

export default ->
  [
    test "creates an empty component graph", ->
      graph = ComponentGraph.make()
      assert ComponentGraph.getVertices(graph).size == 0
      assert ComponentGraph.getEdges(graph).length == 0

    test "adds component vertices with constituent modules", ->
      graph = ComponentGraph.make()
      ComponentGraph.addComponent graph, "pkg-A", [ "file:///app/index.js", "file:///app/helper.js" ]
      
      vertices = ComponentGraph.getVertices graph
      assert.equal vertices.size, 1
      assert vertices.has "pkg-A"
      
      modules = ComponentGraph.getModules graph, "pkg-A"
      assert.equal modules.size, 2
      assert modules.has "file:///app/index.js"
      assert modules.has "file:///app/helper.js"

    test "adds inter-component edges", ->
      graph = ComponentGraph.make()
      ComponentGraph.addComponent graph, "pkg-A", [ "file:///app/index.js" ]
      ComponentGraph.addComponent graph, "pkg-B", [ "file:///node_modules/maeve/index.js" ]

      ComponentGraph.addEdge graph,
        source: "pkg-A"
        target: "pkg-B"
        label: "maeve"

      edges = ComponentGraph.getEdges graph
      assert.equal edges.length, 1
      assert.equal edges[ 0 ].source, "pkg-A"
      assert.equal edges[ 0 ].target, "pkg-B"
      assert.equal edges[ 0 ].label, "maeve"
  ]
