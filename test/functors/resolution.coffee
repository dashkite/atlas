import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Resolution from "../../src/functors/resolution"
import { Registry } from "../../src/resolvers/index"

createFixture = ->
  root = Trie.make()
  maeveNode = Trie.upsertPath root, [ "node", "@dashkite", "maeve@1.0.0", "src", "index.js" ]
  appNode = Trie.upsertPath root, [ "app", "src", "index.js" ]
  appNode.bindings.set "maeve", maeveNode
  root

registerMockResolvers = ->
  Registry.register "node",
    decode: ( _atlasUrl ) -> { resolver: "node" }
    resolve: ( _atlasUrl ) -> "https://cdn.example.com/@dashkite/maeve@1.0.0/src/index.js"
  Registry.register "app",
    decode: ( _atlasUrl ) -> { resolver: "app" }
    resolve: ( _atlasUrl ) -> "/src/index.js"

assertTopology = ( resolvedRoot ) ->
  # Verify topology is intact
  assert ( resolvedRoot.children.has "app" ), "Topology should remain intact"

findResolvedApp = ( resolvedRoot ) ->
  ( ( resolvedRoot.children.get "app" ).children.get "src" ).children.get "index.js"

assertResolvedBinding = ( resolvedApp ) ->
  targetUrl = resolvedApp.bindings.get "maeve"
  assert targetUrl?, "Binding should exist"
  assert.equal typeof targetUrl, "string", "Binding target should now be a string URL"
  # Target was ["npm", "@dashkite", "maeve@1.0.0", "src", "index.js"]
  # Which corresponds to atlas://node/@dashkite/maeve@1.0.0/src/index.js
  assert.equal targetUrl, "https://cdn.example.com/@dashkite/maeve@1.0.0/src/index.js"

export default ->
  [
    test "maps bindings to resolved HTTP/File URLs without restructuring topology", ->
      root = createFixture()
      registerMockResolvers()
      resolvedRoot = Resolution.apply root, [ "node", "app" ]
      assertTopology resolvedRoot
      resolvedApp = findResolvedApp resolvedRoot
      assertResolvedBinding resolvedApp
  ]