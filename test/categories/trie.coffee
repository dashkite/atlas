import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"

export default ->
  [
    test "creates an empty root trie node", ->
      root = Trie.make()
      assert root instanceof Trie
      assert.equal root.segment, ""
      assert.equal root.parent, null
      assert.equal root.children.size, 0
      assert.equal root.bindings.size, 0

    test "upserts path segments and reuses existing intermediate nodes", ->
      root = Trie.make()
      first = root.upsertPath [ "app", "src", "index.js" ]
      second = root.upsertPath [ "app", "src", "helper.js" ]

      assert.equal first.segment, "index.js"
      assert.equal second.segment, "helper.js"
      assert.equal first.parent, second.parent

    test "collects path segments from root to target node", ->
      root = Trie.make()
      node = root.upsertPath [ "node", "@dashkite", "maeve@1.0.0", "index.js" ]

      assert.deepEqual root.getSegments(), []
      assert.deepEqual node.getSegments(), [
        "node"
        "@dashkite"
        "maeve@1.0.0"
        "index.js"
      ]

    test "formats canonical atlas:// address from node path", ->
      root = Trie.make()
      node = root.upsertPath [ "app", "src", "index.js" ]

      assert.equal root.getAddress(), "atlas://"
      assert.equal node.getAddress(), "atlas://app/src/index.js"
  ]
