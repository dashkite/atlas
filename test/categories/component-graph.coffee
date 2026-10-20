import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ComponentGraph from "../../src/categories/component-graph"

assertVertices = ( graph, expected ) ->
  vertices = graph.getVertices()
  assert.equal vertices.size, expected.length
  for name in expected
    assert vertices.has name
  return

assertModules = ( graph, component, expected ) ->
  modules = graph.getModules component
  assert.equal modules.size, expected.length
  for file in expected
    assert modules.has file
  return

createGraph = ->
  graph = ComponentGraph.make()
  graph.addComponent "pkg-A", [ "file:///app/index.js" ]
  graph.addComponent "pkg-B", [
    "file:///node_modules/maeve/index.js"
  ]
  graph

assertEdge = ( graph, expected ) ->
  edges = graph.getEdges()
  assert.equal edges.length, 1
  assert.equal edges[ 0 ].source, expected.source
  assert.equal edges[ 0 ].target, expected.target
  assert.equal edges[ 0 ].label, expected.label

export default ->
  [
    test "creates an empty component graph", ->
      graph = ComponentGraph.make()
      assert graph.getVertices().size == 0
      assert graph.getEdges().length == 0

    test "adds component vertices with constituent modules", ->
      files = [ "file:///app/index.js", "file:///app/helper.js" ]
      graph = ComponentGraph.make()
      graph.addComponent "pkg-A", files
      assertVertices graph, [ "pkg-A" ]
      assertModules graph, "pkg-A", files

    test "adds inter-component edges", ->
      graph = createGraph()
      edge =
        source: "pkg-A"
        target: "pkg-B"
        label: "maeve"
      graph.addEdge edge
      assertEdge graph, edge
  ]