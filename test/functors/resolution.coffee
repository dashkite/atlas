import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Resolution from "../../src/functors/resolution"
import { Registry } from "../../src/resolvers/index"

upsertMaeveNode = ( root ) ->
  Trie.upsertPath root, [
    "node"
    "@dashkite"
    "maeve@1.0.0"
    "src"
    "index.js"
  ]

createFixture = ->
  root = Trie.make()
  maeve = upsertMaeveNode root
  app = Trie.upsertPath root, [ "app", "src", "index.js" ]
  app.bindings.set "maeve", maeve
  root

registerMockResolvers = ->
  Registry.register "node",
    decode: ( _atlasUrl ) -> { resolver: "node" }
    resolve: ( _atlasUrl ) ->
      "https://cdn.example.com/@dashkite/maeve@1.0.0/src/index.js"
  Registry.register "app",
    decode: ( _atlasUrl ) -> { resolver: "app" }
    resolve: ( _atlasUrl ) -> "/src/index.js"

assertTopology = ( root ) ->
  # Verify topology is intact
  assert ( root.children.has "app" ), "Topology should remain intact"

findResolvedApp = ( root ) ->
  ( ( root.children.get "app" ).children.get "src" )
    .children.get "index.js"

assertResolvedBinding = ( app ) ->
  url = app.bindings.get "maeve"
  assert url?, "Binding should exist"
  assert.equal typeof url, "string",
    "Binding target should now be a string URL"
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
        app = findResolvedApp root
        assertResolvedBinding app
  ]