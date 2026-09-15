import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ComponentGraph from "../../src/categories/component-graph"
import TreeIndex from "../../src/categories/tree-index"
import Resolver from "../../src/functors/resolver"

export default ->
  [
    test "projects flat tree index into physical node_modules", ->
      graph = ComponentGraph.make()
      ComponentGraph.addComponent graph, "pkg-root", [ "atlas://application/index.js" ]
      ComponentGraph.addComponent graph, "pkg-A", [ "atlas://node/a/index.js", "atlas://node/a/lib.js" ]
      
      index = TreeIndex.make()
      TreeIndex.addVertex index, "pkg-root"
      TreeIndex.addVertex index, "pkg-A"
      TreeIndex.bind index, [], "pkg-root", "pkg-root"
      TreeIndex.bind index, [], "a", "pkg-A"

      bundle = Resolver.apply graph, index
      
      assert.equal bundle.get("index.js"), "atlas://application/index.js"
      assert.equal bundle.get("node_modules/a/index.js"), "atlas://node/a/index.js"
      assert.equal bundle.get("node_modules/a/lib.js"), "atlas://node/a/lib.js"

    test "projects deeply nested hierarchical tree index", ->
      graph = ComponentGraph.make()
      ComponentGraph.addComponent graph, "pkg-root", [ "atlas://application/index.js" ]
      ComponentGraph.addComponent graph, "pkg-A", [ "atlas://node/a/index.js" ]
      ComponentGraph.addComponent graph, "pkg-B", [ "atlas://node/b/index.js" ]
      
      index = TreeIndex.make()
      TreeIndex.addVertex index, "pkg-root"
      TreeIndex.addVertex index, "pkg-A"
      TreeIndex.addVertex index, "pkg-B"
      
      TreeIndex.bind index, [], "pkg-root", "pkg-root"
      TreeIndex.bind index, [], "a", "pkg-A"
      TreeIndex.bind index, ["pkg-A"], "b", "pkg-B"

      bundle = Resolver.apply graph, index
      
      assert.equal bundle.get("index.js"), "atlas://application/index.js"
      assert.equal bundle.get("node_modules/a/index.js"), "atlas://node/a/index.js"
      assert.equal bundle.get("node_modules/a/node_modules/b/index.js"), "atlas://node/b/index.js"
  ]
