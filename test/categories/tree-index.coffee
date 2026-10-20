import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import TreeIndex from "../../src/categories/tree-index"

lookup = ( index, path, label ) ->
  ( index.getBindings path ).get label

tests =
  empty: ->
    index = TreeIndex.make()
    assert index instanceof TreeIndex
    assert index.getPaths().length == 0
    assert index.getVertices().size == 0

  vertices: ->
    index = TreeIndex.make()
    index.addVertex "pkg-A"
    index.addVertex "pkg-B"
    vertices = index.getVertices()
    assert.equal vertices.size, 2
    assert vertices.has "pkg-A"

  bindings: ->
    index = TreeIndex.make()
    path = [ "pkg-A" ]
    index.bind path, "maeve", "pkg-maeve"
    index.bind path, "cerulean", "pkg-cerulean"
    bindings = index.getBindings path
    assert.equal bindings.size, 2
    assert.equal ( bindings.get "maeve" ), "pkg-maeve"

  paths: ->
    index = TreeIndex.make()
    index.bind [ "pkg-A" ], "maeve", "pkg-maeve"
    index.bind [ "pkg-A", "pkg-B" ], "cerulean", "pkg-cerulean"
    paths = index.getPaths()
    assert.equal paths.length, 2

  isolation: ->
    index = TreeIndex.make()
    index.bind [ "pkg-A" ], "maeve", "pkg-maeve"
    index.bind [ "pkg-A", "pkg-B" ], "cerulean", "pkg-cerulean"
    assert.equal ( lookup index, [ "pkg-A" ], "maeve" ), "pkg-maeve"
    assert.equal ( lookup index, [ "pkg-A", "pkg-B" ], "cerulean" ),
      "pkg-cerulean"

export default ->
  [
    test "creates an empty tree index", tests.empty
    test "retains manifest of explicit vertices", tests.vertices
    test "binds labels to target components within a path", tests.bindings
    test "retrieves distinct paths", tests.paths
    test "retains bindings across distinct paths", tests.isolation
  ]