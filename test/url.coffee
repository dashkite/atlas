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
      parsed = AtlasURL.parse "atlas://cdn@unpkg/@dashkite/joy@0.7.0/src/index.js"
      assert.equal parsed.resolver, "cdn@unpkg"
      assert.equal parsed.pathname, "/@dashkite/joy@0.7.0/src/index.js"

    test "fails fast on malformed URLs", ->
      assert.throws -> AtlasURL.parse "file:///app/src/index.js"

    test "formats descriptor with module", ->
      url = AtlasURL.format
        resolver: "cdn@unpkg"
        module:
          scope: "@dashkite"
          name: "joy"
          version: "0.7.0"
        path: "/src/index.js"
      assert.equal url, "atlas://cdn@unpkg/@dashkite/joy@0.7.0/src/index.js"

    test "formats descriptor without module", ->
      url = AtlasURL.format
        resolver: "application"
        path: "/src/index.js"
      assert.equal url, "atlas://application/src/index.js"
  ]
