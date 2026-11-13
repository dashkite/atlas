import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import resolve from "../../src/functors/resolution"
import { Registry } from "../../src/resolvers/index"

createFixture = ->
  root = Trie.make()
  maeve = root.upsertPath [
    "node", "@dashkite", "maeve@1.0.0", "src", "index.js"
  ]
  application = root.upsertPath [ "app", "src", "index.js" ]
  application.bindings.set "maeve", maeve
  root

registerResolvers = ->
  Registry.register "node",
    decode: ( _url ) -> { resolver: "node" }
    resolve: ( _url ) ->
      "https://cdn.example.com/@dashkite/maeve@1.0.0/src/index.js"
  Registry.register "app",
    decode: ( _url ) -> { resolver: "app" }
    resolve: ( _url ) -> "/src/index.js"

findApplication = ( root ) ->
  [ "app", "src", "index.js" ].reduce ( node, segment ) ->
    node.children.get segment
  , root

assertBinding = ( application ) ->
  url = application.bindings.get "maeve"
  assert url?, "Binding should exist"
  assert.equal url,
    "https://cdn.example.com/@dashkite/maeve@1.0.0/src/index.js"

export default ->
  [
    test (
      "maps bindings to resolved HTTP/File URLs " +
      "without restructuring topology"
    ), ->
      registerResolvers()
      root = resolve createFixture(), [ "node", "app" ]
      assert ( root.children.has "app" )
      application = findApplication root
      assertBinding application
  ]
