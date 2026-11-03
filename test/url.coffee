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

OMITTED_PATH_DESCRIPTOR =
  resolver: "node"
  module:
    scope: undefined
    name: "foo"
    version: "1.0.0"

check =
  roundTrip: ( descriptor, expected, decoded = descriptor ) ->
    url = AtlasURL.encode descriptor
    assert.equal url, expected
    assert.deepEqual ( AtlasURL.decode url ), decoded

Codec =
  application: ->
    [
      test "encodes and decodes descriptor without module", ->
        check.roundTrip APPLICATION_DESCRIPTOR, APPLICATION_URL
      test "fails fast on malformed URLs", ->
        assert.throws -> AtlasURL.decode "not a url"
    ]

  module: ->
    [
      test "encodes and decodes scoped module descriptor", ->
        check.roundTrip SCOPED_DESCRIPTOR, SCOPED_URL
      test "encodes and decodes unscoped module descriptor", ->
        check.roundTrip UNSCOPED_DESCRIPTOR, UNSCOPED_URL
    ]

  root: ->
    [
      test "encodes and decodes scoped package-root descriptor", ->
        check.roundTrip SCOPED_PACKAGE_ROOT_DESCRIPTOR, SCOPED_PACKAGE_ROOT_URL
      test "encodes and decodes unscoped package-root descriptor", ->
        check.roundTrip UNSCOPED_PACKAGE_ROOT_DESCRIPTOR,
          UNSCOPED_PACKAGE_ROOT_URL
    ]

  omitted: ->
    [
      test "encodes and decodes package-root descriptor with omitted path", ->
        check.roundTrip OMITTED_PATH_DESCRIPTOR, UNSCOPED_PACKAGE_ROOT_URL,
          UNSCOPED_PACKAGE_ROOT_DESCRIPTOR
    ]

export default ->
  [
    ...Codec.application()
    ...Codec.module()
    ...Codec.root()
    ...Codec.omitted()
  ]