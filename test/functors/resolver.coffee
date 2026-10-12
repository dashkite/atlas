import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ComponentGraph from "../../src/categories/component-graph"
import TreeIndex from "../../src/categories/tree-index"
import Resolver from "../../src/functors/resolver"
import preset from "../../src/presets/node"

createGraph = (components) ->
  graph = ComponentGraph.make()
  for name, files of components
    ComponentGraph.addComponent graph, name, files
  graph

createFlatGraph = ->
  createGraph
    "pkg-root": [ "atlas://application/index.js" ]
    "pkg-A": [
      "atlas://node/a/index.js"
      "atlas://node/a/lib.js"
    ]

createFlatIndex = ->
  index = TreeIndex.make()
  TreeIndex.addVertex index, "pkg-root"
  TreeIndex.addVertex index, "pkg-A"
  TreeIndex.bind index, [], "pkg-root", "pkg-root"
  TreeIndex.bind index, [], "a", "pkg-A"
  index

assertFlatBundle = (bundle) ->
  assert.equal ( bundle.get "index.js" ), "atlas://application/index.js"
  assert.equal ( bundle.get "node_modules/a/index.js" ),
    "atlas://node/a/index.js"
  assert.equal ( bundle.get "node_modules/a/lib.js" ),
    "atlas://node/a/lib.js"

createNestedGraph = ->
  createGraph
    "pkg-root": [ "atlas://application/index.js" ]
    "pkg-A": [ "atlas://node/a/index.js" ]
    "pkg-B": [ "atlas://node/b/index.js" ]

createNestedIndex = ->
  index = TreeIndex.make()
  TreeIndex.addVertex index, "pkg-root"
  TreeIndex.addVertex index, "pkg-A"
  TreeIndex.addVertex index, "pkg-B"
  TreeIndex.bind index, [], "pkg-root", "pkg-root"
  TreeIndex.bind index, [], "a", "pkg-A"
  TreeIndex.bind index, [ "pkg-A" ], "b", "pkg-B"
  index

assertNestedBundle = (bundle) ->
  assert.equal ( bundle.get "index.js" ), "atlas://application/index.js"
  assert.equal ( bundle.get "node_modules/a/index.js" ),
    "atlas://node/a/index.js"
  assert.equal ( bundle.get "node_modules/a/node_modules/b/index.js" ),
    "atlas://node/b/index.js"

export default ->
  [
    test "projects flat tree index into physical node_modules", ->
      graph = createFlatGraph()
      index = createFlatIndex()
      bundle = Resolver.apply graph, index, preset
      assertFlatBundle bundle

    test "projects deeply nested hierarchical tree index", ->
      graph = createNestedGraph()
      index = createNestedIndex()
      bundle = Resolver.apply graph, index, preset
      assertNestedBundle bundle
  ]