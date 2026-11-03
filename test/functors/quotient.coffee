import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"
import quotient from "../../src/functors/quotient"

maevePackage = "atlas://node/@dashkite/maeve@1.0.0"
enchantPackage = "atlas://local/@dashkite/enchant@2.0.0"

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
    package: maevePackage
    common: "#{ maevePackage }/build/node/src/common.js"
    sublime: "#{ maevePackage }/build/node/src/sublime/index.js"
    modules: [
      "file:///node_modules/maeve/index.js"
      "file:///node_modules/maeve/lib.js"
    ]
  enchant:
    package: enchantPackage
    index: "#{ enchantPackage }/build/node/src/index.js"

addPackageModules = ( graph, id, uris ) ->
  for uri in uris
    graph.addVertex uri
    graph.setAttribute uri, "packageId", id
  return

addInterEdge = ( graph, { source, target, label }) ->
  graph.addEdge
    source: source
    target: target
    label: label
    type: "inter"

buildContractsGraph = ->
  graph = ModuleGraph.make()
  addPackageModules graph, "app", Fixtures.app.modules
  addPackageModules graph, "maeve", Fixtures.maeve.modules
  addInterEdge graph,
    source: Fixtures.app.index
    target: Fixtures.maeve.index
    label: "maeve"
  graph

findComponent = ( graph, uri ) ->
  ( Array.from graph.getVertices()).find ( id ) ->
    ( graph.getModules id ).has uri

verifyAppModules = ( graph, id ) ->
  modules = graph.getModules id
  assert.equal modules.size, 3
  assert modules.has Fixtures.app.helper
  assert modules.has Fixtures.app.utils

verifyEdges = ( graph, source, target ) ->
  edges = graph.getEdges()
  assert.equal edges.length, 1
  assert.equal edges[ 0 ].source, source
  assert.equal edges[ 0 ].target, target
  assert.equal edges[ 0 ].label, "maeve"

verifyDiscreteComponents = ( graph ) ->
  vertices = graph.getVertices()
  assert.equal vertices.size, 2
  app = findComponent graph, Fixtures.app.index
  maeve = findComponent graph, Fixtures.maeve.index
  assert app?
  assert maeve?
  verifyAppModules graph, app
  verifyEdges graph, app, maeve

addDisjointEdges = ( graph ) ->
  addInterEdge graph,
    source: Fixtures.enchant.index
    target: Fixtures.maeve.common
    label: "@dashkite/maeve/common"
  addInterEdge graph,
    source: Fixtures.enchant.index
    target: Fixtures.maeve.sublime
    label: "@dashkite/maeve/sublime"

buildDisjointGraph = ->
  graph = ModuleGraph.make()
  addPackageModules graph, Fixtures.maeve.package, [
    Fixtures.maeve.common
    Fixtures.maeve.sublime
  ]
  addPackageModules graph, Fixtures.enchant.package, [
    Fixtures.enchant.index
  ]
  addDisjointEdges graph
  graph

verifyDisjointComponents = ( graph ) ->
  vertices = graph.getVertices()
  assert.equal vertices.size, 2,
    "Expected disjoint entry points to be collapsed " +
    "into a single package component vertex"

export default ->
  [
    test "contracts intra-component edges into discrete components", ->
      graph = buildContractsGraph()
      verifyDiscreteComponents quotient graph

    test (
      "contracts disjoint entry points of the same package " +
      "into a single component"
    ), ->
      graph = buildDisjointGraph()
      verifyDisjointComponents quotient graph
  ]