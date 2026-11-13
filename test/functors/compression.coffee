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
  application = root.upsertPath [ "app" ]
  application.bindings.set "@dashkite/maeve/common.js", common
  application.bindings.set "@dashkite/maeve/sublime/index.js", sublime
  return

createFixture = ->
  root = Trie.make()
  maeve = setupMaeve root
  setupBindings root, maeve
  { root, maeve }

assertPrefix = ( application, expected ) ->
  assert ( application.bindings.has "@dashkite/maeve/" ),
    "Should have created trailing-slash prefix binding"
  target = application.bindings.get "@dashkite/maeve/"
  assert.equal target, expected

assertPruned = ( application ) ->
  assert.equal ( application.bindings.has "@dashkite/maeve/common.js" ), false
  assert.equal (
    application.bindings.has "@dashkite/maeve/sublime/index.js"
  ), false

export default ->
  [
    test "collapses exact file mappings into directory prefix mappings", ->
      { root, maeve } = createFixture()
      root = compress root
      application = root.children.get "app"
      assertPrefix application, maeve
      assertPruned application
  ]
