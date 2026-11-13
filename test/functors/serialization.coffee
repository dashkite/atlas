import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import serialize from "../../src/functors/serialization"
import { Registry } from "../../src/resolvers/index"

Scopes =
  keys:
    parent: "https://cdn.example.com/@dashkite/maeve@1.0.0/"
    child: "https://cdn.example.com/@dashkite/maeve@1.0.0/node/nested@0.1.0/"
    sibling: "https://cdn.example.com/foo@2.0.0/"

  targets:
    parent: "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
    child: "https://cdn.example.com/nested@0.1.0/index.js"
    sibling: "https://cdn.example.com/foo@2.0.0/index.js"

bindScope = ( node, path, target ) ->
  scope = node.upsertPath path
  scope.bindings.set "./", target
  scope

fixtures =
  base: ->
    root = Trie.make()
    root.bindings.set "helper", "/src/helper.js"
    bindScope root, [ "node", "@dashkite", "maeve@1.0.0" ],
      Scopes.targets.parent
    root

  nested: ->
    root = fixtures.base()
    parent = root.upsertPath [ "node", "@dashkite", "maeve@1.0.0" ]
    bindScope parent, [ "node", "nested@0.1.0" ], Scopes.targets.child
    bindScope root, [ "node", "foo@2.0.0" ], Scopes.targets.sibling
    root

resolver =
  decode: ( _url ) ->
    module:
      scope: "@dashkite"
      name: "maeve"
      version: "1.0.0"
  resolve: ( url ) ->
    "https://cdn.example.com/#{ url.replace "atlas://node/", "" }/"

Assertions =
  imports: ( map ) ->
    assert.equal map.imports[ "helper" ], "/src/helper.js"

  binding: ( scopes, key, target ) ->
    assert scopes[ key ]?
    assert.equal scopes[ key ][ "./" ], target

  scopes: ( map ) ->
    assert map.scopes?
    Assertions.binding map.scopes, Scopes.keys.parent, Scopes.targets.parent

  nested: ( map ) ->
    assert map.scopes?
    Assertions.binding map.scopes, Scopes.keys.parent, Scopes.targets.parent
    Assertions.binding map.scopes, Scopes.keys.child, Scopes.targets.child
    Assertions.binding map.scopes, Scopes.keys.sibling, Scopes.targets.sibling

cases =
  format: ->
    root = fixtures.base()
    Registry.register "node", resolver
    map = serialize root, [ "node" ]
    Assertions.imports map
    Assertions.scopes map

  scopes: ->
    root = fixtures.nested()
    Registry.register "node", resolver
    map = serialize root, [ "node" ]
    Assertions.imports map
    Assertions.nested map

  immutability: ->
    root = fixtures.nested()
    Registry.register "node", resolver
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
      cases.format
    test "serializes nested and sibling scopes correctly",
      cases.scopes
    test "preserves immutability of input Trie",
      cases.immutability
  ]
