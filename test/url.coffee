import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import AtlasURL from "../src/url"

export default ->
  [
    test "parses basic resolver key", ->
      parsed = AtlasURL.parse "atlas://application/src/index.js"
      assert.equal parsed.resolver, "application"
      assert.equal parsed.pathname, "/src/index.js"

    test "parses parameterized resolver key", ->
      parsed =
        AtlasURL.parse "atlas://cdn@unpkg/@dashkite/joy@0.7.0/src/index.js"
      assert.equal parsed.resolver, "cdn@unpkg"
      assert.equal parsed.pathname, "/@dashkite/joy@0.7.0/src/index.js"

    test "fails fast on malformed URLs", ->
      assert.throws -> AtlasURL.parse "not a url"

    test "formats descriptor with module", ->
      url = AtlasURL.format {
        resolver: "cdn@unpkg"
        module:
          scope: "@dashkite"
          name: "joy"
          version: "0.7.0"
        path: "/src/index.js"
      }
      assert.equal url, "atlas://cdn@unpkg/@dashkite/joy@0.7.0/src/index.js"

    test "formats descriptor without module", ->
      url = AtlasURL.format {
        resolver: "application"
        path: "/src/index.js"
      }
      assert.equal url, "atlas://application/src/index.js"

    test "encodes and decodes scoped module descriptor", ->
      descriptor =
        resolver: "cdn@unpkg"
        module:
          scope: "@dashkite"
          name: "joy"
          version: "0.7.0"
        path: "/src/index.js"
      url = AtlasURL.encode descriptor
      assert.equal url, "atlas://cdn@unpkg/@dashkite/joy@0.7.0/src/index.js"
      decoded = AtlasURL.decode url
      assert.deepEqual decoded, descriptor

    test "encodes and decodes unscoped module descriptor", ->
      descriptor =
        resolver: "node"
        module:
          scope: undefined
          name: "foo"
          version: "1.0.0"
        path: "/build/index.js"
      url = AtlasURL.encode descriptor
      assert.equal url, "atlas://node/foo@1.0.0/build/index.js"
      decoded = AtlasURL.decode url
      assert.deepEqual decoded, descriptor
  ]