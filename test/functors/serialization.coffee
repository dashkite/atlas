import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Trie from "../../src/categories/trie"
import Serialization from "../../src/functors/serialization"
import { Registry } from "../../src/resolvers/index"

export default ->
  [
    test "serializes Trie to WHATWG importmap JSON format", ->
      root = Trie.make()
      
      # 1. Global imports (bindings on root)
      root.bindings.set "helper", "/src/helper.js"
      
      # 2. Scoped imports (bindings on descendant node)
      scopeNode = Trie.upsertPath root, ["node", "@dashkite", "maeve@1.0.0"]
      scopeNode.bindings.set "./", "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
      
      Registry.register "node",
        decode: (atlasUrl) -> { module: { scope: "@dashkite", name: "maeve", version: "1.0.0" } }
        resolve: (atlasUrl) -> "https://cdn.example.com/@dashkite/maeve@1.0.0/"

      # Serialize
      importMap = Serialization.apply root, ["node"]
      
      # Verify imports
      assert.equal importMap.imports["helper"], "/src/helper.js"
      
      # Verify scopes
      scopeKey = "https://cdn.example.com/@dashkite/maeve@1.0.0/"
      assert importMap.scopes?, "Scopes block should exist"
      assert importMap.scopes[scopeKey]?, "Scope key should exist"
      assert.equal importMap.scopes[scopeKey]["./"], "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
  ]
