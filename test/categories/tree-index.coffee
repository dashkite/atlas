import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import TreeIndex from "../../src/categories/tree-index"

bindingFor = ( index, path, label ) ->
  ( index.getBindings path ).get label

testEmptyTreeIndex = ->
  index = TreeIndex.make()
  assert index instanceof TreeIndex
  assert index.getPaths().length == 0
  assert index.getVertices().size == 0

testExplicitVertices = ->
  index = TreeIndex.make()
  index.addVertex "pkg-A"
  index.addVertex "pkg-B"
  vertices = index.getVertices()
  assert.equal vertices.size, 2
  assert vertices.has "pkg-A"

testPathBindings = ->
  index = TreeIndex.make()
  path = [ "pkg-A" ]
  index.bind path, "maeve", "pkg-maeve"
  index.bind path, "cerulean", "pkg-cerulean"
  bindings = index.getBindings path
  assert.equal bindings.size, 2
  assert.equal ( bindings.get "maeve" ), "pkg-maeve"

testDistinctPaths = ->
  index = TreeIndex.make()
  index.bind [ "pkg-A" ], "maeve", "pkg-maeve"
  index.bind [ "pkg-A", "pkg-B" ], "cerulean", "pkg-cerulean"
  paths = index.getPaths()
  assert.equal paths.length, 2

testBindingsAcrossPaths = ->
  index = TreeIndex.make()
  index.bind [ "pkg-A" ], "maeve", "pkg-maeve"
  index.bind [ "pkg-A", "pkg-B" ], "cerulean", "pkg-cerulean"
  assert.equal ( bindingFor index, [ "pkg-A" ], "maeve" ), "pkg-maeve"
  assert.equal ( bindingFor index, [ "pkg-A", "pkg-B" ], "cerulean" ),
    "pkg-cerulean"

export default ->
  [
    test "creates an empty tree index", testEmptyTreeIndex
    test "retains manifest of explicit vertices", testExplicitVertices
    test "binds labels to target components within a path", testPathBindings
    test "retrieves distinct paths", testDistinctPaths
    test "retains bindings across distinct paths", testBindingsAcrossPaths
  ]