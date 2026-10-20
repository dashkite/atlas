import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import resolve from "../../src/functors/resolution"
import { Registry } from "../../src/resolvers/index"

upsertMaeve = ( root ) ->
  root.upsertPath [
    "node"
    "@dashkite"
    "maeve@1.0.0"
    "src"
    "index.js"
  ]

createFixture = ->
  root = Trie.make()
  maeve = upsertMaeve root
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

assertTopology = ( root ) ->
  # Verify topology is intact
  assert ( root.children.has "app" ), "Topology should remain intact"

findApplication = ( root ) ->
  (( root.children.get "app" ).children.get "src" )
    .children.get "index.js"

assertBinding = ( application ) ->
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
        registerResolvers()
        root = resolve createFixture(), [ "node", "app" ]
        assertTopology root
        application = findApplication root
        assertBinding application
  ]