import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ComponentGraph from "../../src/categories/component-graph"
import TreeIndex from "../../src/categories/tree-index"
import resolve from "../../src/functors/resolver"
import preset from "../../src/presets/node"

createGraph = ( components ) ->
  graph = ComponentGraph.make()
  for name, files of components
    graph.addComponent name, files
  graph

flat =
  graph: ->
    createGraph
      "pkg-root": [ "atlas://application/index.js" ]
      "pkg-A": [
        "atlas://node/a/index.js"
        "atlas://node/a/lib.js"
      ]

  index: ->
    index = TreeIndex.make()
    index.addVertex "pkg-root"
    index.addVertex "pkg-A"
    index.bind [], "pkg-root", "pkg-root"
    index.bind [], "a", "pkg-A"
    index

  assert: ( bundle ) ->
    assert.equal ( bundle.get "index.js" ), "atlas://application/index.js"
    assert.equal ( bundle.get "node_modules/a/index.js" ),
      "atlas://node/a/index.js"
    assert.equal ( bundle.get "node_modules/a/lib.js" ),
      "atlas://node/a/lib.js"

nested =
  graph: ->
    createGraph
      "pkg-root": [ "atlas://application/index.js" ]
      "pkg-A": [ "atlas://node/a/index.js" ]
      "pkg-B": [ "atlas://node/b/index.js" ]

  index: ->
    index = TreeIndex.make()
    index.addVertex "pkg-root"
    index.addVertex "pkg-A"
    index.addVertex "pkg-B"
    index.bind [], "pkg-root", "pkg-root"
    index.bind [], "a", "pkg-A"
    index.bind [ "pkg-A" ], "b", "pkg-B"
    index

  assert: ( bundle ) ->
    assert.equal ( bundle.get "index.js" ), "atlas://application/index.js"
    assert.equal ( bundle.get "node_modules/a/index.js" ),
      "atlas://node/a/index.js"
    assert.equal ( bundle.get "node_modules/a/node_modules/b/index.js" ),
      "atlas://node/b/index.js"

export default ->
  [
    test "projects flat tree index into physical node_modules", ->
      flat.assert resolve flat.graph(), flat.index(), preset

    test "projects deeply nested hierarchical tree index", ->
      nested.assert resolve nested.graph(), nested.index(), preset
  ]