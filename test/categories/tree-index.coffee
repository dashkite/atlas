import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import TreeIndex from "../../src/categories/tree-index"
import Path from "../../src/categories/path"

export default ->
  [
    test "creates an empty tree index", ->
      index = TreeIndex.make()
      assert TreeIndex.getPaths(index).length == 0
      assert TreeIndex.getVertices(index).size == 0

    test "retains manifest of explicit vertices", ->
      index = TreeIndex.make()
      TreeIndex.addVertex index, "pkg-A"
      TreeIndex.addVertex index, "pkg-B"
      
      vertices = TreeIndex.getVertices index
      assert.equal vertices.size, 2
      assert vertices.has "pkg-A"

    test "binds labels to target components within a path", ->
      index = TreeIndex.make()
      path = [ "pkg-A" ]

      TreeIndex.bind index, path, "maeve", "pkg-maeve"
      TreeIndex.bind index, path, "cerulean", "pkg-cerulean"

      bindings = TreeIndex.getBindings index, path
      assert.equal bindings.size, 2
      assert.equal bindings.get("maeve"), "pkg-maeve"

    test "retrieves distinct paths", ->
      index = TreeIndex.make()
      p1 = [ "pkg-A" ]
      p2 = [ "pkg-A", "pkg-B" ]

      TreeIndex.bind index, p1, "maeve", "pkg-maeve"
      TreeIndex.bind index, p2, "cerulean", "pkg-cerulean"

      paths = TreeIndex.getPaths index
      assert.equal paths.length, 2
      
      # The paths array should deeply equal our inputs (or reference them)
      # We'll assert we can get bindings back for both.
      assert.equal TreeIndex.getBindings(index, p1).get("maeve"), "pkg-maeve"
      assert.equal TreeIndex.getBindings(index, p2).get("cerulean"), "pkg-cerulean"
  ]
