import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Compression from "../../src/functors/compression"

setupMaeveNode = ( root ) ->
  Trie.upsertPath root, [
    "npm"
    "@dashkite"
    "maeve@1.0.0"
    "build"
    "node"
    "src"
  ]

setupTargetPaths = ( root ) ->
  maeve = setupMaeveNode root
  common = Trie.upsertPath maeve, [ "common.js" ]
  sublime = Trie.upsertPath maeve, [ "sublime", "index.js" ]
  { maeve, common, sublime }

setupBindings = ( root, { common, sublime } ) ->
  app = Trie.upsertPath root, [ "app" ]
  app.bindings.set "@dashkite/maeve/common.js", common
  app.bindings.set "@dashkite/maeve/sublime/index.js", sublime

createFixture = ->
  root = Trie.make()
  targets = setupTargetPaths root
  setupBindings root, targets
  { root, maeve: targets.maeve }

assertPrefixBinding = ( app, expected ) ->
  assert ( app.bindings.has "@dashkite/maeve/" ),
    "Should have created trailing-slash prefix binding"
  target = app.bindings.get "@dashkite/maeve/"
  assert.equal target, expected,
    "Prefix binding should point to common ancestor node"

assertPrunedBindings = ( app ) ->
  assert.equal ( app.bindings.has "@dashkite/maeve/common.js" ),
    false,
    "Should have pruned specific file binding"
  assert.equal ( app.bindings.has "@dashkite/maeve/sublime/index.js" ),
    false,
    "Should have pruned specific file binding"

export default ->
  [
    test "collapses exact file mappings into directory prefix mappings", ->
      { root, maeve } = createFixture()
      root = Compression.apply root
      app = root.children.get "app"
      assertPrefixBinding app, maeve
      assertPrunedBindings app
  ]