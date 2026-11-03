import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"
import quotient from "../../src/functors/quotient"

Packages =
  maeve: "atlas://node/@dashkite/maeve@1.0.0"
  enchant: "atlas://local/@dashkite/enchant@2.0.0"

Fixtures =
  app:
    index: "file:///app/index.js"
    helper: "file:///app/helper.js"
    utils: "file:///app/utils.js"
    package: "app"
    modules: [
      "file:///app/index.js"
      "file:///app/helper.js"
      "file:///app/utils.js"
    ]
  maeve:
    index: "file:///node_modules/maeve/index.js"
    lib: "file:///node_modules/maeve/lib.js"
    package: Packages.maeve
    common: "#{ Packages.maeve }/build/node/src/common.js"
    sublime: "#{ Packages.maeve }/build/node/src/sublime/index.js"
    modules: [
      "file:///node_modules/maeve/index.js"
      "file:///node_modules/maeve/lib.js"
    ]
  enchant:
    package: Packages.enchant
    index: "#{ Packages.enchant }/build/node/src/index.js"

addModules = ( graph, id, uris ) ->
  for uri in uris
    graph.addVertex uri
    graph.setAttribute uri, "packageId", id
  return

addEdge = ( graph, { source, target, label }) ->
  graph.addEdge
    source: source
    target: target
    label: label
    type: "inter"

addEdges = ( graph ) ->
  addEdge graph,
    source: Fixtures.enchant.index
    target: Fixtures.maeve.common
    label: "@dashkite/maeve/common"
  addEdge graph,
    source: Fixtures.enchant.index
    target: Fixtures.maeve.sublime
    label: "@dashkite/maeve/sublime"

Graphs =
  contracts: ->
    graph = ModuleGraph.make()
    addModules graph, "app", Fixtures.app.modules
    addModules graph, "maeve", Fixtures.maeve.modules
    addEdge graph,
      source: Fixtures.app.index
      target: Fixtures.maeve.index
      label: "maeve"
    graph

  disjoint: ->
    graph = ModuleGraph.make()
    addModules graph, Fixtures.maeve.package, [
      Fixtures.maeve.common
      Fixtures.maeve.sublime
    ]
    addModules graph, Fixtures.enchant.package, [
      Fixtures.enchant.index
    ]
    addEdges graph
    graph

findComponent = ( graph, uri ) ->
  ( Array.from graph.getVertices()).find ( id ) ->
    ( graph.getModules id ).has uri

Assertions =
  modules: ( graph, id ) ->
    modules = graph.getModules id
    assert.equal modules.size, 3
    assert modules.has Fixtures.app.helper
    assert modules.has Fixtures.app.utils

  edges: ( graph, source, target ) ->
    edges = graph.getEdges()
    assert.equal edges.length, 1
    assert.equal edges[ 0 ].source, source
    assert.equal edges[ 0 ].target, target
    assert.equal edges[ 0 ].label, "maeve"

  discrete: ( graph ) ->
    vertices = graph.getVertices()
    assert.equal vertices.size, 2
    app = findComponent graph, Fixtures.app.index
    maeve = findComponent graph, Fixtures.maeve.index
    assert app?
    assert maeve?
    Assertions.modules graph, app
    Assertions.edges graph, app, maeve

  disjoint: ( graph ) ->
    vertices = graph.getVertices()
    assert.equal vertices.size, 2,
      "Expected disjoint entry points to be collapsed " +
      "into a single package component vertex"

export default ->
  [
    test "contracts intra-component edges into discrete components", ->
      Assertions.discrete quotient Graphs.contracts()

    test (
      "contracts disjoint entry points of the same package " +
      "into a single component"
    ), ->
      Assertions.disjoint quotient Graphs.disjoint()
  ]