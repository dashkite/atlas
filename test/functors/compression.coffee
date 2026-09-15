import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Compression from "../../src/functors/compression"

export default ->
  [
    test "collapses exact file mappings into directory prefix mappings", ->
      root = Trie.make()
      
      # Setup target paths
      maeveNode = Trie.upsertPath root, ["npm", "@dashkite", "maeve@1.0.0", "build", "node", "src"]
      commonNode = Trie.upsertPath maeveNode, ["common.js"]
      sublimeNode = Trie.upsertPath maeveNode, ["sublime", "index.js"]
      
      appNode = Trie.upsertPath root, ["app"]
      
      # Add uncompressed bindings
      appNode.bindings.set "@dashkite/maeve/common.js", commonNode
      appNode.bindings.set "@dashkite/maeve/sublime/index.js", sublimeNode
      
      # Apply Compression
      compressedRoot = Compression.apply root
      
      appCompressed = compressedRoot.children.get("app")
      
      # Assertions
      assert appCompressed.bindings.has("@dashkite/maeve/"), "Should have created trailing-slash prefix binding"
      
      target = appCompressed.bindings.get("@dashkite/maeve/")
      assert.equal target, maeveNode, "Prefix binding should point to common ancestor node"
      
      assert.equal appCompressed.bindings.has("@dashkite/maeve/common.js"), false, "Should have pruned specific file binding"
      assert.equal appCompressed.bindings.has("@dashkite/maeve/sublime/index.js"), false, "Should have pruned specific file binding"
  ]
