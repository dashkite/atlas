import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"
import ComponentGraph from "../../src/categories/component-graph"
import Quotient from "../../src/functors/quotient"

APP_INDEX = "file:///app/index.js"
APP_HELPER = "file:///app/helper.js"
APP_UTILS = "file:///app/utils.js"
MAEVE_INDEX = "file:///node_modules/maeve/index.js"
MAEVE_LIB = "file:///node_modules/maeve/lib.js"

APP_MODULES = [ APP_INDEX, APP_HELPER, APP_UTILS ]
MAEVE_MODULES = [ MAEVE_INDEX, MAEVE_LIB ]

MAEVE_PACKAGE = "atlas://node/@dashkite/maeve@1.0.0"
ENCHANT_PACKAGE = "atlas://local/@dashkite/enchant@2.0.0"

MAEVE_COMMON = "#{ MAEVE_PACKAGE }/build/node/src/common.js"
MAEVE_SUBLIME = "#{ MAEVE_PACKAGE }/build/node/src/sublime/index.js"
ENCHANT_INDEX = "#{ ENCHANT_PACKAGE }/build/node/src/index.js"

addPackageModules = ( graph, packageId, uris ) ->
  for uri in uris
    ModuleGraph.addVertex graph, uri
    ModuleGraph.setAttribute graph, uri, "packageId", packageId
  return

addInterEdge = ( graph, source, target, label ) ->
  ModuleGraph.addEdge graph,
    source: source
    target: target
    label: label
    type: "inter"

buildContractsGraph = ->
  graph = ModuleGraph.make()
  addPackageModules graph, "app", APP_MODULES
  addPackageModules graph, "maeve", MAEVE_MODULES
  addInterEdge graph, APP_INDEX, MAEVE_INDEX, "maeve"
  graph

findComponent = ( graph, uri ) ->
  for id from ComponentGraph.getVertices graph
    if ( ComponentGraph.getModules graph, id ).has uri
      return id
  null

verifyAppModules = ( graph, componentId ) ->
  modules = ComponentGraph.getModules graph, componentId
  assert.equal modules.size, 3
  assert modules.has APP_HELPER
  assert modules.has APP_UTILS

verifyEdges = ( graph, sourceId, targetId ) ->
  edges = ComponentGraph.getEdges graph
  assert.equal edges.length, 1
  assert.equal edges[0].source, sourceId
  assert.equal edges[0].target, targetId
  assert.equal edges[0].label, "maeve"

verifyDiscreteComponents = ( componentGraph ) ->
  vertices = ComponentGraph.getVertices componentGraph
  assert.equal vertices.size, 2
  appId = findComponent componentGraph, APP_INDEX
  maeveId = findComponent componentGraph, MAEVE_INDEX
  assert appId?
  assert maeveId?
  verifyAppModules componentGraph, appId
  verifyEdges componentGraph, appId, maeveId

buildDisjointGraph = ->
  graph = ModuleGraph.make()
  addPackageModules graph, MAEVE_PACKAGE, [ MAEVE_COMMON, MAEVE_SUBLIME ]
  addPackageModules graph, ENCHANT_PACKAGE, [ ENCHANT_INDEX ]
  addInterEdge graph, ENCHANT_INDEX, MAEVE_COMMON, "@dashkite/maeve/common"
  addInterEdge graph, ENCHANT_INDEX, MAEVE_SUBLIME, "@dashkite/maeve/sublime"
  graph

verifyDisjointComponents = ( componentGraph ) ->
  vertices = ComponentGraph.getVertices componentGraph
  assert.equal vertices.size, 2,
    "Expected disjoint entry points to be collapsed
    into a single package component vertex"

export default ->
  [
    test "contracts intra-component edges into discrete components", ->
      graph = buildContractsGraph()
      componentGraph = Quotient.apply graph
      verifyDiscreteComponents componentGraph

    test "contracts disjoint entry points of the same package
    into a single component", ->
      graph = buildDisjointGraph()
      componentGraph = Quotient.apply graph
      verifyDisjointComponents componentGraph
  ]