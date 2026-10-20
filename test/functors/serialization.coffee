import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import serialize from "../../src/functors/serialization"
import { Registry } from "../../src/resolvers/index"

createFixture = ->
  root = Trie.make()
  root.bindings.set "helper", "/src/helper.js"
  node = root.upsertPath [ "node", "@dashkite", "maeve@1.0.0" ]
  node.bindings.set "./",
    "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
  root

resolver =
  decode: ( _url ) ->
    module:
      scope: "@dashkite"
      name: "maeve"
      version: "1.0.0"
  resolve: ( url ) ->
    "https://cdn.example.com/#{ url.replace "atlas://node/", "" }/"

registerResolver = ->
  Registry.register "node", resolver

createMultiScopeFixture = ->
  root = Trie.make()
  root.bindings.set "helper", "/src/helper.js"
  nodeA = root.upsertPath [ "node", "@dashkite", "maeve@1.0.0" ]
  nodeA.bindings.set "./",
    "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
  child = nodeA.upsertPath [ "node", "nested@0.1.0" ]
  child.bindings.set "./",
    "https://cdn.example.com/nested@0.1.0/index.js"
  nodeB = root.upsertPath [ "node", "foo@2.0.0" ]
  nodeB.bindings.set "./",
    "https://cdn.example.com/foo@2.0.0/index.js"
  root

verifyImports = ( map ) ->
  assert.equal map.imports["helper"], "/src/helper.js"

verifyScopes = ( map ) ->
  key = "https://cdn.example.com/@dashkite/maeve@1.0.0/"
  assert map.scopes?, "Scopes block should exist"
  assert map.scopes[key]?, "Scope key should exist"
  assert.equal map.scopes[key]["./"],
    "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"

verifyMultiScopes = ( map ) ->
  keyA = "https://cdn.example.com/@dashkite/maeve@1.0.0/"
  keyChild = "https://cdn.example.com/@dashkite/maeve@1.0.0/node/nested@0.1.0/"
  keyB = "https://cdn.example.com/foo@2.0.0/"
  assert map.scopes?, "Scopes block should exist"
  assert map.scopes[ keyA ]?, "Scope keyA should exist"
  assert map.scopes[ keyChild ]?, "Scope keyChild should exist"
  assert map.scopes[ keyB ]?, "Scope keyB should exist"
  assert.equal map.scopes[ keyA ][ "./" ],
    "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
  assert.equal map.scopes[ keyChild ][ "./" ],
    "https://cdn.example.com/nested@0.1.0/index.js"
  assert.equal map.scopes[ keyB ][ "./" ],
    "https://cdn.example.com/foo@2.0.0/index.js"

export default ->
  [
    test "serializes Trie to WHATWG importmap JSON format", ->
      root = createFixture()
      registerResolver()
      map = serialize root, [ "node" ]
      verifyImports map
      verifyScopes map
    test "serializes nested and sibling scopes correctly", ->
      root = createMultiScopeFixture()
      registerResolver()
      map = serialize root, [ "node" ]
      verifyImports map
      verifyMultiScopes map
    test "preserves immutability of input Trie", ->
      root = createMultiScopeFixture()
      registerResolver()
      bindingsBefore = new Map root.bindings
      childrenBefore = new Map root.children
      serialize root, [ "node" ]
      assert.deepEqual ( Array.from root.bindings.entries() ),
        Array.from bindingsBefore.entries()
      assert.deepEqual ( Array.from root.children.entries() ),
        Array.from childrenBefore.entries()
  ]