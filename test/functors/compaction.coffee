import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import compact from "../../src/functors/compaction"

setupSource = ( root, target ) ->
  node = root.upsertPath [ "app", "src", "index.js" ]
  node.bindings.set "a", target
  node = root.upsertPath [ "app", "src", "helper.js" ]
  node.bindings.set "a", target

setupLibrary = ( root, target ) ->
  node = root.upsertPath [ "app", "lib", "index.js" ]
  node.bindings.set "a", target

setupTrie = ( targets ) ->
  root = Trie.make()
  setupSource root, targets.source
  setupLibrary root, targets.library
  root

verifyApplication = ( root ) ->
  application = root.children.get "app"
  source = application.children.get "src"
  assert.equal ( application.bindings.has "a" ), false
  assert.equal ( source.bindings.has "a" ), false

verifyLibrary = ( root, target ) ->
  application = root.children.get "app"
  library = application.children.get "lib"
  index = library.children.get "index.js"
  assert.equal ( library.bindings.get "a" ), target
  assert.equal ( index.bindings.has "a" ), false

verifyCompacted = ( root, targets ) ->
  assert.equal ( root.bindings.get "a" ), targets.source
  verifyApplication root
  verifyLibrary root, targets.library

testCompaction = ->
  targets =
    source: Trie.make "targetA"
    library: Trie.make "targetB"
  root = setupTrie targets
  compacted = compact root
  verifyCompacted compacted, targets

export default ->
  [
    test "safely lifts scopes without label collisions", testCompaction
  ]