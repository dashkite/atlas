import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import AtlasURL from "../src/url"

SCOPED_URL = "atlas://cdn@unpkg/@dashkite/joy@0.7.0/src/index.js"
UNSCOPED_URL = "atlas://node/foo@1.0.0/build/index.js"
APPLICATION_URL = "atlas://application/src/index.js"

SCOPED_DESCRIPTOR =
  resolver: "cdn@unpkg"
  module:
    scope: "@dashkite"
    name: "joy"
    version: "0.7.0"
  path: "/src/index.js"

UNSCOPED_DESCRIPTOR =
  resolver: "node"
  module:
    scope: undefined
    name: "foo"
    version: "1.0.0"
  path: "/build/index.js"

APPLICATION_DESCRIPTOR =
  resolver: "application"
  path: "/src/index.js"

SCOPED_PACKAGE_ROOT_URL = "atlas://cdn@unpkg/@dashkite/joy@0.7.0"
UNSCOPED_PACKAGE_ROOT_URL = "atlas://node/foo@1.0.0"

SCOPED_PACKAGE_ROOT_DESCRIPTOR =
  resolver: "cdn@unpkg"
  module:
    scope: "@dashkite"
    name: "joy"
    version: "0.7.0"
  path: ""

UNSCOPED_PACKAGE_ROOT_DESCRIPTOR =
  resolver: "node"
  module:
    scope: undefined
    name: "foo"
    version: "1.0.0"
  path: ""

check =
  parsed: ( url, resolver, pathname ) ->
    parsed = AtlasURL.parse url
    assert.equal parsed.resolver, resolver
    assert.equal parsed.pathname, pathname

  roundTrip: ( descriptor, expected ) ->
    url = AtlasURL.encode descriptor
    assert.equal url, expected
    assert.deepEqual ( AtlasURL.decode url ), descriptor

parse = ->
  [
    test "parses basic resolver key", ->
      check.parsed APPLICATION_URL, "application", "/src/index.js"
    test "parses parameterized resolver key", ->
      check.parsed SCOPED_URL, "cdn@unpkg", "/@dashkite/joy@0.7.0/src/index.js"
    test "fails fast on malformed URLs", ->
      assert.throws -> AtlasURL.parse "not a url"
  ]

format = ->
  [
    test "formats descriptor with module", ->
      assert.equal ( AtlasURL.format SCOPED_DESCRIPTOR ), SCOPED_URL
    test "formats descriptor without module", ->
      assert.equal ( AtlasURL.format APPLICATION_DESCRIPTOR ), APPLICATION_URL
  ]

codec = ->
  [
    test "encodes and decodes scoped module descriptor", ->
      check.roundTrip SCOPED_DESCRIPTOR, SCOPED_URL
    test "encodes and decodes unscoped module descriptor", ->
      check.roundTrip UNSCOPED_DESCRIPTOR, UNSCOPED_URL
    test "encodes and decodes scoped package-root descriptor", ->
      check.roundTrip SCOPED_PACKAGE_ROOT_DESCRIPTOR, SCOPED_PACKAGE_ROOT_URL
    test "encodes and decodes unscoped package-root descriptor", ->
      check.roundTrip UNSCOPED_PACKAGE_ROOT_DESCRIPTOR,
        UNSCOPED_PACKAGE_ROOT_URL
    test "encodes and decodes package-root descriptor with omitted path", ->
      descriptor =
        resolver: "node"
        module:
          scope: undefined
          name: "foo"
          version: "1.0.0"
      url = AtlasURL.encode descriptor
      assert.equal url, UNSCOPED_PACKAGE_ROOT_URL
      assert.deepEqual ( AtlasURL.decode url ), UNSCOPED_PACKAGE_ROOT_DESCRIPTOR
  ]

export default ->
  [
    ...parse()
    ...format()
    ...codec()
  ]