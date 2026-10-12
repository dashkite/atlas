import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Compaction from "../../src/functors/compaction"

# 1. Non-colliding lift
# src/index.js has binding `a -> targetA`
# src/helper.js has binding `a -> targetA`
# Both should lift to `src`, and then to `app`, and then to `root`
setupSourceNodes = (root, target) ->
  node = Trie.upsertPath root, [ "app", "src", "index.js" ]
  node.bindings.set "a", target
  node = Trie.upsertPath root, [ "app", "src", "helper.js" ]
  node.bindings.set "a", target

# 2. Colliding lift
# lib/index.js has binding `a -> targetB`
# It lifts to `lib`
# When `lib` tries to lift to `app`, `app` already has `a -> targetA`.
# Since targetA != targetB, it must trap the binding at `lib`.
setupLibraryNode = (root, target) ->
  node = Trie.upsertPath root, [ "app", "lib", "index.js" ]
  node.bindings.set "a", target

setupTrie = (targetA, targetB) ->
  root = Trie.make()
  setupSourceNodes root, targetA
  setupLibraryNode root, targetB
  root

verifyApplication = (root) ->
  application = root.children.get "app"
  source = application.children.get "src"
  assert.equal ( application.bindings.has "a" ), false
  assert.equal ( source.bindings.has "a" ), false

verifyLibrary = (root, targetB) ->
  application = root.children.get "app"
  library = application.children.get "lib"
  index = library.children.get "index.js"
  assert.equal ( library.bindings.get "a" ), targetB
  assert.equal ( index.bindings.has "a" ), false

verifyCompacted = (root, targetA, targetB) ->
  assert.equal ( root.bindings.get "a" ), targetA
  verifyApplication root
  verifyLibrary root, targetB

testCompaction = ->
  targetA = Trie.make "targetA"
  targetB = Trie.make "targetB"
  root = setupTrie targetA, targetB
  compacted = Compaction.apply root
  verifyCompacted compacted, targetA, targetB

export default ->
  [
    test "safely lifts scopes without label collisions", testCompaction
  ]