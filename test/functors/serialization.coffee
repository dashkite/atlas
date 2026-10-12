import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Serialization from "../../src/functors/serialization"
import { Registry } from "../../src/resolvers/index"

createFixture = ->
  root = Trie.make()
  root.bindings.set "helper", "/src/helper.js"
  node = Trie.upsertPath root, [ "node", "@dashkite", "maeve@1.0.0" ]
  node.bindings.set "./",
    "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
  root

resolver =
  decode: (_url) ->
    module:
      scope: "@dashkite"
      name: "maeve"
      version: "1.0.0"
  resolve: (_url) -> "https://cdn.example.com/@dashkite/maeve@1.0.0/"

registerResolver = ->
  Registry.register "node", resolver

verifyImports = (map) ->
  assert.equal map.imports["helper"], "/src/helper.js"

verifyScopes = (map) ->
  key = "https://cdn.example.com/@dashkite/maeve@1.0.0/"
  assert map.scopes?, "Scopes block should exist"
  assert map.scopes[key]?, "Scope key should exist"
  assert.equal map.scopes[key]["./"],
    "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"

export default ->
  [
    test "serializes Trie to WHATWG importmap JSON format", ->
      root = createFixture()
      registerResolver()
      map = Serialization.apply root, [ "node" ]
      verifyImports map
      verifyScopes map
  ]