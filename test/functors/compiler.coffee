import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import { pipe } from "@dashkite/joy/function"
import ComponentGraph from "../../src/categories/component-graph"
import compile from "../../src/functors/compiler"

Fixtures =
  linear:
    components: [
      [ "pkg-root", [ "file:///index.js" ]]
      [ "pkg-A", [ "file:///node_modules/a/index.js" ]]
      [ "pkg-B", [ "file:///node_modules/b/index.js" ]]
    ]
    edges: [
      { source: "pkg-root", target: "pkg-A", label: "a" }
      { source: "pkg-A", target: "pkg-B", label: "b" }
    ]

  isolation:
    components: [
      [ "pkg-root", [ "file:///index.js" ]]
      [ "pkg-A", [ "file:///node_modules/a/index.js" ]]
      [ "pkg-C", [ "file:///node_modules/c/index.js" ]]
      [ "pkg-B-v1", [ "file:///node_modules/a/node_modules/b/index.js" ]]
      [ "pkg-B-v2", [ "file:///node_modules/c/node_modules/b/index.js" ]]
    ]
    edges: [
      { source: "pkg-root", target: "pkg-A", label: "a" }
      { source: "pkg-root", target: "pkg-C", label: "c" }
      { source: "pkg-A", target: "pkg-B-v1", label: "b" }
      { source: "pkg-C", target: "pkg-B-v2", label: "b" }
    ]

buildGraph = ( components, edges ) ->
  graph = ComponentGraph.make()
  for [ name, files ] in components
    graph.addComponent name, files
  for edge in edges
    graph.addEdge edge
  graph

createLinearGraph = ->
  buildGraph Fixtures.linear.components, Fixtures.linear.edges

createIsolationGraph = ->
  buildGraph Fixtures.isolation.components, Fixtures.isolation.edges

verifyBinding = ( index, { path, key, expected }) ->
  bindings = index.getBindings path
  assert.equal ( bindings.get key ), expected

assertBaselineIndex = ( index ) ->
  verifyBinding index, path: [], key: "pkg-root", expected: "pkg-root"
  verifyBinding index, path: [ "pkg-root" ], key: "a", expected: "pkg-A"
  verifyBinding index,
    path: [ "pkg-root", "pkg-A" ]
    key: "b"
    expected: "pkg-B"

assertCompactedIndex = ( index ) ->
  verifyBinding index, path: [], key: "pkg-root", expected: "pkg-root"
  verifyBinding index, path: [], key: "a", expected: "pkg-A"
  verifyBinding index, path: [], key: "b", expected: "pkg-B"

###
Collision on label "b": pkg-B-v1 and pkg-B-v2 cannot hoist.
However, pkg-A and pkg-C have no collisions, so they MUST hoist to root.
The conflicting dependencies (pkg-B-v1, pkg-B-v2) will be hierarchically
embedded.
###
assertIsolationIndex = ( index ) ->
  verifyBinding index, path: [], key: "pkg-root", expected: "pkg-root"
  verifyBinding index, path: [], key: "a", expected: "pkg-A"
  verifyBinding index, path: [], key: "c", expected: "pkg-C"
  verifyBinding index, path: [ "pkg-A" ], key: "b", expected: "pkg-B-v1"
  verifyBinding index, path: [ "pkg-C" ], key: "b", expected: "pkg-B-v2"

testBaseline = pipe [
  createLinearGraph
  ( graph ) -> compile graph, compact: false
  assertBaselineIndex
]

testCompaction = pipe [
  createLinearGraph
  ( graph ) -> compile graph, compact: true
  assertCompactedIndex
]

testIsolation = pipe [
  createIsolationGraph
  ( graph ) -> compile graph, compact: true
  assertIsolationIndex
]

export default ->
  [
    test "baseline tree embedding (uncompacted)", testBaseline
    test "topological compaction (unconflicted rebasing)", testCompaction
    test "topological isolation (allows parent hoisting with nested children)",
      testIsolation
  ]