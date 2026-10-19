import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import AtlasURL from "../src/url"

scopedURL = "atlas://cdn@unpkg/@dashkite/joy@0.7.0/src/index.js"
unscopedURL = "atlas://node/foo@1.0.0/build/index.js"
applicationURL = "atlas://application/src/index.js"

scopedDescriptor =
  resolver: "cdn@unpkg"
  module:
    scope: "@dashkite"
    name: "joy"
    version: "0.7.0"
  path: "/src/index.js"

unscopedDescriptor =
  resolver: "node"
  module:
    scope: undefined
    name: "foo"
    version: "1.0.0"
  path: "/build/index.js"

applicationDescriptor =
  resolver: "application"
  path: "/src/index.js"

assertParsed = ( url, resolver, pathname ) ->
  parsed = AtlasURL.parse url
  assert.equal parsed.resolver, resolver
  assert.equal parsed.pathname, pathname

assertRoundTrip = ( descriptor, expected ) ->
  url = AtlasURL.encode descriptor
  assert.equal url, expected
  assert.deepEqual ( AtlasURL.decode url ), descriptor

parseTests = ->
  [
    test "parses basic resolver key", ->
      assertParsed applicationURL, "application", "/src/index.js"
    test "parses parameterized resolver key", ->
      assertParsed scopedURL, "cdn@unpkg", "/@dashkite/joy@0.7.0/src/index.js"
    test "fails fast on malformed URLs", ->
      assert.throws -> AtlasURL.parse "not a url"
  ]

formatTests = ->
  [
    test "formats descriptor with module", ->
      assert.equal ( AtlasURL.format scopedDescriptor ), scopedURL
    test "formats descriptor without module", ->
      assert.equal ( AtlasURL.format applicationDescriptor ), applicationURL
  ]

codecTests = ->
  [
    test "encodes and decodes scoped module descriptor", ->
      assertRoundTrip scopedDescriptor, scopedURL
    test "encodes and decodes unscoped module descriptor", ->
      assertRoundTrip unscopedDescriptor, unscopedURL
  ]

export default ->
  [
    ...parseTests()
    ...formatTests()
    ...codecTests()
  ]