import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ComponentGraph from "../../src/categories/component-graph"
import TreeIndex from "../../src/categories/tree-index"
import Compiler from "../../src/functors/compiler"

export default ->
  [
    test "baseline tree embedding (uncompacted)", ->
      graph = ComponentGraph.make()
      ComponentGraph.addComponent graph, "pkg-root", ["file:///index.js"]
      ComponentGraph.addComponent graph, "pkg-A", ["file:///node_modules/a/index.js"]
      ComponentGraph.addComponent graph, "pkg-B", ["file:///node_modules/b/index.js"]
      
      ComponentGraph.addEdge graph, { source: "pkg-root", target: "pkg-A", label: "a" }
      ComponentGraph.addEdge graph, { source: "pkg-A", target: "pkg-B", label: "b" }

      index = Compiler.apply graph, { compact: false }
      
      b0 = TreeIndex.getBindings index, []
      assert.equal b0.get("pkg-root"), "pkg-root"

      b1 = TreeIndex.getBindings index, ["pkg-root"]
      assert.equal b1.get("a"), "pkg-A"

      b2 = TreeIndex.getBindings index, ["pkg-root", "pkg-A"]
      assert.equal b2.get("b"), "pkg-B"

    test "topological compaction (unconflicted rebasing)", ->
      graph = ComponentGraph.make()
      ComponentGraph.addComponent graph, "pkg-root", ["file:///index.js"]
      ComponentGraph.addComponent graph, "pkg-A", ["file:///node_modules/a/index.js"]
      ComponentGraph.addComponent graph, "pkg-B", ["file:///node_modules/b/index.js"]
      
      ComponentGraph.addEdge graph, { source: "pkg-root", target: "pkg-A", label: "a" }
      ComponentGraph.addEdge graph, { source: "pkg-A", target: "pkg-B", label: "b" }

      index = Compiler.apply graph, { compact: true }
      
      b0 = TreeIndex.getBindings index, []
      assert.equal b0.get("pkg-root"), "pkg-root"
      assert.equal b0.get("a"), "pkg-A"
      assert.equal b0.get("b"), "pkg-B"

    test "topological isolation (allows parent hoisting with nested children)", ->
      graph = ComponentGraph.make()
      ComponentGraph.addComponent graph, "pkg-root", ["file:///index.js"]
      ComponentGraph.addComponent graph, "pkg-A", ["file:///node_modules/a/index.js"]
      ComponentGraph.addComponent graph, "pkg-C", ["file:///node_modules/c/index.js"]
      ComponentGraph.addComponent graph, "pkg-B-v1", ["file:///node_modules/a/node_modules/b/index.js"]
      ComponentGraph.addComponent graph, "pkg-B-v2", ["file:///node_modules/c/node_modules/b/index.js"]

      ComponentGraph.addEdge graph, { source: "pkg-root", target: "pkg-A", label: "a" }
      ComponentGraph.addEdge graph, { source: "pkg-root", target: "pkg-C", label: "c" }
      ComponentGraph.addEdge graph, { source: "pkg-A", target: "pkg-B-v1", label: "b" }
      ComponentGraph.addEdge graph, { source: "pkg-C", target: "pkg-B-v2", label: "b" }

      index = Compiler.apply graph, { compact: true }
      
      # Collision on label "b". pkg-B-v1 and pkg-B-v2 cannot hoist.
      # However, pkg-A and pkg-C have no collisions, so they MUST hoist to root.
      # The conflicting dependencies (pkg-B-v1, pkg-B-v2) will be hierarchically embedded.

      bRoot = TreeIndex.getBindings index, []
      assert.equal bRoot.get("pkg-root"), "pkg-root"
      assert.equal bRoot.get("a"), "pkg-A"
      assert.equal bRoot.get("c"), "pkg-C"
      
      bA = TreeIndex.getBindings index, ["pkg-A"]
      assert.equal bA.get("b"), "pkg-B-v1"

      bC = TreeIndex.getBindings index, ["pkg-C"]
      assert.equal bC.get("b"), "pkg-B-v2"
  ]
