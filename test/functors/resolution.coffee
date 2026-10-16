import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Resolution from "../../src/functors/resolution"
import { Registry } from "../../src/resolvers/index"

upsertMaeveNode = ( root ) ->
  root.upsertPath [
    "node"
    "@dashkite"
    "maeve@1.0.0"
    "src"
    "index.js"
  ]

createFixture = ->
  root = Trie.make()
  maeve = upsertMaeveNode root
  application = root.upsertPath [ "app", "src", "index.js" ]
  application.bindings.set "maeve", maeve
  root

registerMockResolvers = ->
  Registry.register "node",
    decode: ( _url ) -> { resolver: "node" }
    resolve: ( _url ) ->
      "https://cdn.example.com/@dashkite/maeve@1.0.0/src/index.js"
  Registry.register "app",
    decode: ( _url ) -> { resolver: "app" }
    resolve: ( _url ) -> "/src/index.js"

assertTopology = ( root ) ->
  # Verify topology is intact
  assert ( root.children.has "app" ), "Topology should remain intact"

findResolvedApplication = ( root ) ->
  ( ( root.children.get "app" ).children.get "src" )
    .children.get "index.js"

assertResolvedBinding = ( application ) ->
  url = application.bindings.get "maeve"
  assert url?, "Binding should exist"
  # Target was ["npm", "@dashkite", "maeve@1.0.0", "src", "index.js"]
  # Which corresponds to atlas://node/@dashkite/maeve@1.0.0/src/index.js
  assert.equal url,
    "https://cdn.example.com/@dashkite/maeve@1.0.0/src/index.js"

export default ->
  [
    test "maps bindings to resolved HTTP/File URLs
      without restructuring topology", ->
        registerMockResolvers()
        root = Resolution.apply createFixture(), [ "node", "app" ]
        assertTopology root
        application = findResolvedApplication root
        assertResolvedBinding application
  ]