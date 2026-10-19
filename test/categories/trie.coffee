import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"

testEmptyRootNode = ->
  root = Trie.make()
  assert root instanceof Trie
  assert.equal root.segment, ""
  assert.equal root.parent, null
  assert.equal root.children.size, 0
  assert.equal root.bindings.size, 0

testUpsertPath = ->
  root = Trie.make()
  first = root.upsertPath [ "app", "src", "index.js" ]
  second = root.upsertPath [ "app", "src", "helper.js" ]

  assert.equal first.segment, "index.js"
  assert.equal second.segment, "helper.js"
  assert.equal first.parent, second.parent

testGetSegments = ->
  root = Trie.make()
  node = root.upsertPath [ "node", "@dashkite", "maeve@1.0.0", "index.js" ]
  assert.deepEqual root.getSegments(), []
  assert.deepEqual node.getSegments(), [
    "node"
    "@dashkite"
    "maeve@1.0.0"
    "index.js"
  ]

testGetAddress = ->
  root = Trie.make()
  node = root.upsertPath [ "app", "src", "index.js" ]

  assert.equal root.getAddress(), "atlas://"
  assert.equal node.getAddress(), "atlas://app/src/index.js"

export default ->
  [
    test "creates an empty root trie node", testEmptyRootNode
    test "upserts path segments and reuses existing intermediate nodes",
      testUpsertPath
    test "collects path segments from root to target node", testGetSegments
    test "formats canonical atlas:// address from node path", testGetAddress
  ]
