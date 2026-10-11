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
      node = Trie.upsertPath root, ["node", "@dashkite", "maeve@1.0.0"]
      node.bindings.set "./", "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"

      Registry.register "node",
        decode: (_url) -> { module: { scope: "@dashkite", name: "maeve", version: "1.0.0" } }
        resolve: (_url) -> "https://cdn.example.com/@dashkite/maeve@1.0.0/"

      # Serialize
      map = Serialization.apply root, ["node"]

      # Verify imports
      assert.equal map.imports["helper"], "/src/helper.js"

      # Verify scopes
      key = "https://cdn.example.com/@dashkite/maeve@1.0.0/"
      assert map.scopes?, "Scopes block should exist"
      assert map.scopes[key]?, "Scope key should exist"
      assert.equal map.scopes[key]["./"],
        "https://cdn.example.com/@dashkite/maeve@1.0.0/lib/index.js"
  ]