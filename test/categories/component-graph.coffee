import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ComponentGraph from "../../src/categories/component-graph"

assertVertices = ( graph, expected ) ->
  vertices = ComponentGraph.getVertices graph
  assert.equal vertices.size, expected.length
  for name in expected
    assert vertices.has name
  return

assertModules = ( graph, component, expected ) ->
  modules = ComponentGraph.getModules graph, component
  assert.equal modules.size, expected.length
  for file in expected
    assert modules.has file
  return

createGraphWithComponents = ->
  graph = ComponentGraph.make()
  ComponentGraph.addComponent graph, "pkg-A", [ "file:///app/index.js" ]
  ComponentGraph.addComponent graph, "pkg-B", [
    "file:///node_modules/maeve/index.js"
  ]
  graph

assertEdge = ( graph, expected ) ->
  edges = ComponentGraph.getEdges graph
  assert.equal edges.length, 1
  assert.equal edges[ 0 ].source, expected.source
  assert.equal edges[ 0 ].target, expected.target
  assert.equal edges[ 0 ].label, expected.label

export default ->
  [
    test "creates an empty component graph", ->
      graph = ComponentGraph.make()
      assert ( ComponentGraph.getVertices graph ).size == 0
      assert ( ComponentGraph.getEdges graph ).length == 0

    test "adds component vertices with constituent modules", ->
      files = [ "file:///app/index.js", "file:///app/helper.js" ]
      graph = ComponentGraph.make()
      ComponentGraph.addComponent graph, "pkg-A", files
      assertVertices graph, [ "pkg-A" ]
      assertModules graph, "pkg-A", files

    test "adds inter-component edges", ->
      graph = createGraphWithComponents()
      edge =
        source: "pkg-A"
        target: "pkg-B"
        label: "maeve"
      ComponentGraph.addEdge graph, edge
      assertEdge graph, edge
  ]