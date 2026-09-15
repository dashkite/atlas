import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Compaction from "../../src/functors/compaction"

export default ->
  [
    test "safely lifts scopes without label collisions", ->
      root = Trie.make()
      
      # Setup target nodes
      targetA = Trie.make("targetA")
      targetB = Trie.make("targetB")
      
      # Setup trie: root -> app -> src -> index.js
      #                           -> helper.js
      #                 -> lib -> index.js
      
      # 1. Non-colliding lift
      # src/index.js has binding `a -> targetA`
      # src/helper.js has binding `a -> targetA`
      # Both should lift to `src`, and then to `app`, and then to `root`
      
      appNode = Trie.upsertPath root, ["app"]
      srcNode = Trie.upsertPath root, ["app", "src"]
      srcIndexNode = Trie.upsertPath root, ["app", "src", "index.js"]
      srcHelperNode = Trie.upsertPath root, ["app", "src", "helper.js"]
      
      srcIndexNode.bindings.set "a", targetA
      srcHelperNode.bindings.set "a", targetA
      
      # 2. Colliding lift
      # lib/index.js has binding `a -> targetB`
      # It lifts to `lib`
      # When `lib` tries to lift to `app`, `app` already has `a -> targetA`.
      # Since targetA != targetB, it must trap the binding at `lib`.
      
      libNode = Trie.upsertPath root, ["app", "lib"]
      libIndexNode = Trie.upsertPath root, ["app", "lib", "index.js"]
      
      libIndexNode.bindings.set "a", targetB
      
      # Apply Compaction Endofunctor
      compactedRoot = Compaction.apply root
      
      # Assertions
      # The binding for "a -> targetA" should have bubbled all the way up to root
      assert.equal compactedRoot.bindings.get("a"), targetA
      
      # The src node and its children should be empty of bindings
      assert.equal compactedRoot.children.get("app").bindings.has("a"), false
      assert.equal compactedRoot.children.get("app").children.get("src").bindings.has("a"), false
      
      # The lib node should have the trapped binding "a -> targetB"
      libCompacted = compactedRoot.children.get("app").children.get("lib")
      assert.equal libCompacted.bindings.get("a"), targetB
      
      # The lib/index.js node should be empty of bindings, since it lifted to lib
      assert.equal libCompacted.children.get("index.js").bindings.has("a"), false
  ]
