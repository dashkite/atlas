import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Compression from "../../src/functors/compression"

setupTargetPaths = ( root ) ->
  maeveNode = Trie.upsertPath root, [ "npm", "@dashkite", "maeve@1.0.0", "build", "node", "src" ]
  commonNode = Trie.upsertPath maeveNode, [ "common.js" ]
  sublimeNode = Trie.upsertPath maeveNode, [ "sublime", "index.js" ]
  { maeveNode, commonNode, sublimeNode }

setupBindings = ( root, { commonNode, sublimeNode } ) ->
  appNode = Trie.upsertPath root, [ "app" ]
  appNode.bindings.set "@dashkite/maeve/common.js", commonNode
  appNode.bindings.set "@dashkite/maeve/sublime/index.js", sublimeNode

createFixture = ->
  root = Trie.make()
  targets = setupTargetPaths root
  setupBindings root, targets
  { root, maeveNode: targets.maeveNode }

assertPrefixBinding = ( appNode, expectedNode ) ->
  assert ( appNode.bindings.has "@dashkite/maeve/" ),
    "Should have created trailing-slash prefix binding"
  target = appNode.bindings.get "@dashkite/maeve/"
  assert.equal target, expectedNode, "Prefix binding should point to common ancestor node"

assertPrunedBindings = ( appNode ) ->
  assert.equal ( appNode.bindings.has "@dashkite/maeve/common.js" ), false,
    "Should have pruned specific file binding"
  assert.equal ( appNode.bindings.has "@dashkite/maeve/sublime/index.js" ), false,
    "Should have pruned specific file binding"

export default ->
  [
    test "collapses exact file mappings into directory prefix mappings", ->
      { root, maeveNode } = createFixture()
      compressedRoot = Compression.apply root
      appCompressed = compressedRoot.children.get "app"
      assertPrefixBinding appCompressed, maeveNode
      assertPrunedBindings appCompressed
  ]