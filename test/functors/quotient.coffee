import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"
import quotient from "../../src/functors/quotient"

Packages =
  maeve: "atlas://node/@dashkite/maeve@1.0.0"
  enchant: "atlas://local/@dashkite/enchant@2.0.0"

Modules =
  application:
    index: "file:///app/index.js"
    helper: "file:///app/helper.js"
    utilities: "file:///app/utils.js"
  maeve:
    index: "file:///node_modules/maeve/index.js"
    library: "file:///node_modules/maeve/lib.js"
    common: "#{ Packages.maeve }/build/node/src/common.js"
    sublime: "#{ Packages.maeve }/build/node/src/sublime/index.js"
  enchant:
    index: "#{ Packages.enchant }/build/node/src/index.js"

Fixtures =
  contracts:
    modules: [
      [
        "app"
        [
          Modules.application.index
          Modules.application.helper
          Modules.application.utilities
        ]
      ]
      [ "maeve", [ Modules.maeve.index, Modules.maeve.library ]]
    ]
    edges: [
      {
        source: Modules.application.index
        target: Modules.maeve.index
        label: "maeve"
      }
    ]

  disjoint:
    modules: [
      [ Packages.maeve, [ Modules.maeve.common, Modules.maeve.sublime ]]
      [ Packages.enchant, [ Modules.enchant.index ]]
    ]
    edges: [
      {
        source: Modules.enchant.index
        target: Modules.maeve.common
        label: "@dashkite/maeve/common"
      }
      {
        source: Modules.enchant.index
        target: Modules.maeve.sublime
        label: "@dashkite/maeve/sublime"
      }
    ]

addModules = ( graph, id, uris ) ->
  for uri in uris
    graph.addVertex uri
    graph.setAttribute uri, "packageId", id
  return

addEdges = ( graph, edges ) ->
  for edge in edges
    graph.addEdge { edge..., type: "inter" }
  return

buildGraph = ({ modules, edges }) ->
  graph = ModuleGraph.make()
  for [ id, uris ] in modules
    addModules graph, id, uris
  addEdges graph, edges
  graph

findComponent = ( graph, uri ) ->
  ( Array.from graph.getVertices()).find ( id ) ->
    ( graph.getModules id ).has uri

Assertions =
  modules: ( graph, id ) ->
    modules = graph.getModules id
    assert.equal modules.size, 3
    assert modules.has Modules.application.helper
    assert modules.has Modules.application.utilities

  edges: ( graph, source, target ) ->
    edges = graph.getEdges()
    assert.equal edges.length, 1
    assert.equal edges[ 0 ].source, source
    assert.equal edges[ 0 ].target, target
    assert.equal edges[ 0 ].label, "maeve"

  discrete: ( graph ) ->
    vertices = graph.getVertices()
    assert.equal vertices.size, 2
    application = findComponent graph, Modules.application.index
    maeve = findComponent graph, Modules.maeve.index
    assert application?
    assert maeve?
    Assertions.modules graph, application
    Assertions.edges graph, application, maeve

export default ->
  [
    test "contracts intra-component edges into discrete components", ->
      Assertions.discrete quotient buildGraph Fixtures.contracts

    test (
      "contracts disjoint entry points of the same package " +
      "into a single component"
    ), ->
      graph = quotient buildGraph Fixtures.disjoint
      assert.equal graph.getVertices().size, 2
  ]
