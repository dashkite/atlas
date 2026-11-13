import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import serialize from "../../src/functors/serialization"
import { Registry } from "../../src/resolvers/index"

Targets =
  parent: "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
  child: "https://cdn.example.com/nested@0.1.0/index.js"
  sibling: "https://cdn.example.com/foo@2.0.0/index.js"

Expectations =
  base:
    imports:
      helper: "/src/helper.js"
    scopes:
      "https://cdn.example.com/@dashkite/maeve@1.0.0/":
        "./": Targets.parent

  nested:
    imports:
      helper: "/src/helper.js"
    scopes:
      "https://cdn.example.com/@dashkite/maeve@1.0.0/":
        "./": Targets.parent
      "https://cdn.example.com/@dashkite/maeve@1.0.0/node/nested@0.1.0/":
        "./": Targets.child
      "https://cdn.example.com/foo@2.0.0/":
        "./": Targets.sibling

bindScope = ( node, path, target ) ->
  scope = node.upsertPath path
  scope.bindings.set "./", target
  scope

Fixtures =
  base: ->
    root = Trie.make()
    root.bindings.set "helper", "/src/helper.js"
    bindScope root, [ "node", "@dashkite", "maeve@1.0.0" ], Targets.parent
    root

  nested: ->
    root = Fixtures.base()
    parent = root.upsertPath [ "node", "@dashkite", "maeve@1.0.0" ]
    bindScope parent, [ "node", "nested@0.1.0" ], Targets.child
    bindScope root, [ "node", "foo@2.0.0" ], Targets.sibling
    root

resolver =
  decode: ( _url ) ->
    module:
      scope: "@dashkite"
      name: "maeve"
      version: "1.0.0"
  resolve: ( url ) ->
    "https://cdn.example.com/#{ url.replace "atlas://node/", "" }/"

export default ->
  [
    test "serializes Trie to WHATWG importmap JSON format", ->
      Registry.register "node", resolver
      map = serialize Fixtures.base(), [ "node" ]
      assert.deepEqual map, Expectations.base

    test "serializes nested and sibling scopes correctly", ->
      Registry.register "node", resolver
      map = serialize Fixtures.nested(), [ "node" ]
      assert.deepEqual map, Expectations.nested

    test "preserves immutability of input Trie", ->
      root = Fixtures.nested()
      Registry.register "node", resolver
      bindings = new Map root.bindings
      children = new Map root.children
      serialize root, [ "node" ]
      assert.deepEqual ( Array.from root.bindings ), Array.from bindings
      assert.deepEqual ( Array.from root.children ), Array.from children
  ]
