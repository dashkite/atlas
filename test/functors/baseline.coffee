import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"
import Baseline from "../../src/functors/baseline"

addVertices = (graph) ->
  ModuleGraph.addVertex graph, "atlas://app/src/index.js"
  ModuleGraph.addVertex graph, "atlas://app/node_modules/maeve/index.js"
  ModuleGraph.addVertex graph, "atlas://app/src/helper.js"

addInterEdge = (graph) ->
  ModuleGraph.addEdge graph,
    source: "atlas://app/src/index.js"
    target: "atlas://app/node_modules/maeve/index.js"
    label: "maeve"
    type: "inter"

addIntraEdge = (graph) ->
  ModuleGraph.addEdge graph,
    source: "atlas://app/src/index.js"
    target: "atlas://app/src/helper.js"
    label: "./helper.js"
    type: "intra"

buildFixtureGraph = ->
  graph = ModuleGraph.make()
  addVertices graph
  addInterEdge graph
  addIntraEdge graph
  graph

getIndexNode = (trie) ->
  node = trie.children.get "app"
  assert node?, "expected app node"
  node = node.children.get "src"
  assert node?, "expected src node"
  node = node.children.get "index.js"
  assert node?, "expected index.js node"
  node

verifyBindings = (node) ->
  assert.equal node.bindings.size, 1
  target = node.bindings.get "maeve"
  assert target?, "expected maeve binding"
  assert.equal target.segment, "index.js"
  assert !node.bindings.has "./helper.js"

verifyTrie = (trie) ->
  node = getIndexNode trie
  verifyBindings node

export default ->
  [
    test "creates exact, module-scoped baseline mappings", ->
      graph = buildFixtureGraph()
      trie = Baseline.apply graph
      verifyTrie trie
  ]