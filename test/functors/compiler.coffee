import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ComponentGraph from "../../src/categories/component-graph"
import TreeIndex from "../../src/categories/tree-index"
import Compiler from "../../src/functors/compiler"

LINEAR_COMPONENTS = [
  ["pkg-root", ["file:///index.js"]]
  ["pkg-A", ["file:///node_modules/a/index.js"]]
  ["pkg-B", ["file:///node_modules/b/index.js"]]
]

LINEAR_EDGES = [
  { source: "pkg-root", target: "pkg-A", label: "a" }
  { source: "pkg-A", target: "pkg-B", label: "b" }
]

ISOLATION_COMPONENTS = [
  ["pkg-root", ["file:///index.js"]]
  ["pkg-A", ["file:///node_modules/a/index.js"]]
  ["pkg-C", ["file:///node_modules/c/index.js"]]
  ["pkg-B-v1", ["file:///node_modules/a/node_modules/b/index.js"]]
  ["pkg-B-v2", ["file:///node_modules/c/node_modules/b/index.js"]]
]

ISOLATION_EDGES = [
  { source: "pkg-root", target: "pkg-A", label: "a" }
  { source: "pkg-root", target: "pkg-C", label: "c" }
  { source: "pkg-A", target: "pkg-B-v1", label: "b" }
  { source: "pkg-C", target: "pkg-B-v2", label: "b" }
]

buildGraph = (components, edges) ->
  graph = ComponentGraph.make()
  for [name, files] in components
    ComponentGraph.addComponent graph, name, files
  for edge in edges
    ComponentGraph.addEdge graph, edge
  graph

buildLinearGraph = ->
  buildGraph LINEAR_COMPONENTS, LINEAR_EDGES

buildIsolationGraph = ->
  buildGraph ISOLATION_COMPONENTS, ISOLATION_EDGES

verifyBinding = (index, path, key, expected) ->
  bindings = TreeIndex.getBindings index, path
  assert.equal ( bindings.get key ), expected

verifyBaseline = (index) ->
  verifyBinding index, [], "pkg-root", "pkg-root"
  verifyBinding index, ["pkg-root"], "a", "pkg-A"
  verifyBinding index, ["pkg-root", "pkg-A"], "b", "pkg-B"

verifyCompacted = (index) ->
  verifyBinding index, [], "pkg-root", "pkg-root"
  verifyBinding index, [], "a", "pkg-A"
  verifyBinding index, [], "b", "pkg-B"

# Collision on label "b": pkg-B-v1 and pkg-B-v2 cannot hoist.
# However, pkg-A and pkg-C have no collisions, so they MUST hoist to root.
# The conflicting dependencies (pkg-B-v1, pkg-B-v2) will be hierarchically
# embedded.
verifyIsolation = (index) ->
  verifyBinding index, [], "pkg-root", "pkg-root"
  verifyBinding index, [], "a", "pkg-A"
  verifyBinding index, [], "c", "pkg-C"
  verifyBinding index, ["pkg-A"], "b", "pkg-B-v1"
  verifyBinding index, ["pkg-C"], "b", "pkg-B-v2"

export default ->
  [
    test "baseline tree embedding (uncompacted)", ->
      graph = buildLinearGraph()
      index = Compiler.apply graph, { compact: false }
      verifyBaseline index

    test "topological compaction (unconflicted rebasing)", ->
      graph = buildLinearGraph()
      index = Compiler.apply graph, { compact: true }
      verifyCompacted index

    test "topological isolation
      (allows parent hoisting with nested children)", ->
      graph = buildIsolationGraph()
      index = Compiler.apply graph, { compact: true }
      verifyIsolation index
  ]