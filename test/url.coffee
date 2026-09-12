import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import AtlasURL from "../src/url"

export default ->
  [
    test "parses application urls", ->
      parsed = AtlasURL.parse "atlas://application/src/index.js"
      assert.equal parsed.type, "application"
      assert.equal parsed.specifier, undefined
      assert.equal parsed.subpath, "src/index.js"

    test "parses npm urls (unscoped)", ->
      parsed = AtlasURL.parse "atlas://npm/maeve/lib/index.js"
      assert.equal parsed.type, "npm"
      assert.equal parsed.specifier, "maeve"
      assert.equal parsed.subpath, "lib/index.js"

    test "parses npm urls (scoped)", ->
      parsed = AtlasURL.parse "atlas://npm/@dashkite/cerulean/index.js"
      assert.equal parsed.type, "npm"
      assert.equal parsed.specifier, "@dashkite/cerulean"
      assert.equal parsed.subpath, "index.js"

    test "parses local urls", ->
      parsed = AtlasURL.parse "atlas://local/@dashkite/cerulean/index.js"
      assert.equal parsed.type, "local"
      assert.equal parsed.specifier, "@dashkite/cerulean"
      assert.equal parsed.subpath, "index.js"

    test "fails fast on malformed URLs", ->
      assert.throws -> AtlasURL.parse "file:///app/src/index.js"
      assert.throws -> AtlasURL.parse "atlas://npm/" # Missing specifier

    test "formats application urls", ->
      url = AtlasURL.format
        type: "application"
        subpath: "src/index.js"
      assert.equal url, "atlas://application/src/index.js"

    test "formats scoped npm urls", ->
      url = AtlasURL.format
        type: "npm"
        specifier: "@dashkite/cerulean"
        subpath: "index.js"
      assert.equal url, "atlas://npm/@dashkite/cerulean/index.js"
  ]
