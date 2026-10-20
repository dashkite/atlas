import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import serialize from "../../src/functors/serialization"
import { Registry } from "../../src/resolvers/index"

SCOPE_KEYS =
  parent: "https://cdn.example.com/@dashkite/maeve@1.0.0/"
  child: "https://cdn.example.com/@dashkite/maeve@1.0.0/node/nested@0.1.0/"
  sibling: "https://cdn.example.com/foo@2.0.0/"

SCOPE_TARGETS =
  parent: "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
  child: "https://cdn.example.com/nested@0.1.0/index.js"
  sibling: "https://cdn.example.com/foo@2.0.0/index.js"

bindScopePath = ( node, path, target ) ->
  scope = node.upsertPath path
  scope.bindings.set "./", target
  scope

createFixture = ->
  root = Trie.make()
  root.bindings.set "helper", "/src/helper.js"
  bindScopePath root, [ "node", "@dashkite", "maeve@1.0.0" ],
    SCOPE_TARGETS.parent
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
  root = createFixture()
  parent = root.upsertPath [ "node", "@dashkite", "maeve@1.0.0" ]
  bindScopePath parent, [ "node", "nested@0.1.0" ], SCOPE_TARGETS.child
  bindScopePath root, [ "node", "foo@2.0.0" ], SCOPE_TARGETS.sibling
  root

verifyImports = ( map ) ->
  assert.equal map.imports["helper"], "/src/helper.js"

verifyScopeBinding = ( scopes, scopeKey, expectedTarget ) ->
  assert scopes[ scopeKey ]?, "Scope key #{ scopeKey } should exist"
  assert.equal scopes[ scopeKey ][ "./" ], expectedTarget

verifyScopes = ( map ) ->
  assert map.scopes?, "Scopes block should exist"
  verifyScopeBinding map.scopes, SCOPE_KEYS.parent, SCOPE_TARGETS.parent

verifyMultiScopes = ( map ) ->
  assert map.scopes?, "Scopes block should exist"
  verifyScopeBinding map.scopes, SCOPE_KEYS.parent, SCOPE_TARGETS.parent
  verifyScopeBinding map.scopes, SCOPE_KEYS.child, SCOPE_TARGETS.child
  verifyScopeBinding map.scopes, SCOPE_KEYS.sibling, SCOPE_TARGETS.sibling

testImportmapFormat = ->
  root = createFixture()
  registerResolver()
  map = serialize root, [ "node" ]
  verifyImports map
  verifyScopes map

testMultiScopeSerialization = ->
  root = createMultiScopeFixture()
  registerResolver()
  map = serialize root, [ "node" ]
  verifyImports map
  verifyMultiScopes map

testTrieImmutability = ->
  root = createMultiScopeFixture()
  registerResolver()
  bindings = new Map root.bindings
  children = new Map root.children
  serialize root, [ "node" ]
  assert.deepEqual ( Array.from root.bindings.entries()),
    Array.from bindings.entries()
  assert.deepEqual ( Array.from root.children.entries()),
    Array.from children.entries()

export default ->
  [
    test "serializes Trie to WHATWG importmap JSON format",
      testImportmapFormat
    test "serializes nested and sibling scopes correctly",
      testMultiScopeSerialization
    test "preserves immutability of input Trie",
      testTrieImmutability
  ]