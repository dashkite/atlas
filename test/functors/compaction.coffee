import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Compaction from "../../src/functors/compaction"

export default ->
  [
    test "safely lifts scopes without label collisions", ->
      root = Trie.make()

      # Setup target nodes
      targetA = Trie.make "targetA"
      targetB = Trie.make "targetB"

      # Setup trie: root -> app -> src -> index.js
      #                           -> helper.js
      #                 -> lib -> index.js

      # 1. Non-colliding lift
      # src/index.js has binding `a -> targetA`
      # src/helper.js has binding `a -> targetA`
      # Both should lift to `src`, and then to `app`, and then to `root`

      sourceIndexNode = Trie.upsertPath root, ["app", "src", "index.js"]
      sourceHelperNode = Trie.upsertPath root, ["app", "src", "helper.js"]

      sourceIndexNode.bindings.set "a", targetA
      sourceHelperNode.bindings.set "a", targetA

      # 2. Colliding lift
      # lib/index.js has binding `a -> targetB`
      # It lifts to `lib`
      # When `lib` tries to lift to `app`, `app` already has `a -> targetA`.
      # Since targetA != targetB, it must trap the binding at `lib`.

      libraryIndexNode = Trie.upsertPath root, ["app", "lib", "index.js"]

      libraryIndexNode.bindings.set "a", targetB

      # Apply Compaction Endofunctor
      compactedRoot = Compaction.apply root

      # Assertions
      # The binding for "a -> targetA" should have bubbled all the way up to root
      assert.equal ( compactedRoot.bindings.get "a" ), targetA

      # The src node and its children should be empty of bindings
      applicationCompacted = compactedRoot.children.get "app"
      assert.equal ( applicationCompacted.bindings.has "a" ), false
      assert.equal ( ( applicationCompacted.children.get "src" ).bindings.has "a" ), false

      # The lib node should have the trapped binding "a -> targetB"
      libraryCompacted = applicationCompacted.children.get "lib"
      assert.equal ( libraryCompacted.bindings.get "a" ), targetB

      # The lib/index.js node should be empty of bindings, since it lifted to lib
      assert.equal ( ( libraryCompacted.children.get "index.js" ).bindings.has "a" ), false
  ]