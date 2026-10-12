import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import TreeIndex from "../../src/categories/tree-index"

bindingFor = ( index, path, label ) ->
  ( TreeIndex.getBindings index, path ).get label

export default ->
  [
    test "creates an empty tree index", ->
      index = TreeIndex.make()
      assert ( TreeIndex.getPaths index ).length == 0
      assert ( TreeIndex.getVertices index ).size == 0

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
      assert.equal ( bindings.get "maeve" ), "pkg-maeve"

    test "retrieves distinct paths", ->
      index = TreeIndex.make()
      TreeIndex.bind index, [ "pkg-A" ], "maeve", "pkg-maeve"
      TreeIndex.bind index, [ "pkg-A", "pkg-B" ], "cerulean", "pkg-cerulean"
      paths = TreeIndex.getPaths index
      assert.equal paths.length, 2

    test "retains bindings across distinct paths", ->
      index = TreeIndex.make()
      TreeIndex.bind index, [ "pkg-A" ], "maeve", "pkg-maeve"
      TreeIndex.bind index, [ "pkg-A", "pkg-B" ], "cerulean", "pkg-cerulean"
      assert.equal ( bindingFor index, [ "pkg-A" ], "maeve" ), "pkg-maeve"
      assert.equal ( bindingFor index, [ "pkg-A", "pkg-B" ], "cerulean" ),
        "pkg-cerulean"
  ]