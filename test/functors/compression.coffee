import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import compress from "../../src/functors/compression"

setupMaeve = ( root ) ->
  root.upsertPath [
    "npm"
    "@dashkite"
    "maeve@1.0.0"
    "build"
    "node"
    "src"
  ]

setupBindings = ( root, maeve ) ->
  common = maeve.upsertPath [ "common.js" ]
  sublime = maeve.upsertPath [ "sublime", "index.js" ]
  app = root.upsertPath [ "app" ]
  app.bindings.set "@dashkite/maeve/common.js", common
  app.bindings.set "@dashkite/maeve/sublime/index.js", sublime
  return

createFixture = ->
  root = Trie.make()
  maeve = setupMaeve root
  setupBindings root, maeve
  { root, maeve }

assertPrefix = ( app, expected ) ->
  assert ( app.bindings.has "@dashkite/maeve/" ),
    "Should have created trailing-slash prefix binding"
  target = app.bindings.get "@dashkite/maeve/"
  assert.equal target, expected,
    "Prefix binding should point to common ancestor node"

assertPruned = ( app ) ->
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
      root = compress root
      app = root.children.get "app"
      assertPrefix app, maeve
      assertPruned app
  ]