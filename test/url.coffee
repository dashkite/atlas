import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import AtlasURL from "../src/url"

Fixtures =
  urls:
    scoped: "atlas://cdn@unpkg/@dashkite/joy@0.7.0/src/index.js"
    unscoped: "atlas://node/foo@1.0.0/build/index.js"
    application: "atlas://application/src/index.js"
    root:
      scoped: "atlas://cdn@unpkg/@dashkite/joy@0.7.0"
      unscoped: "atlas://node/foo@1.0.0"

  descriptors:
    scoped:
      resolver: "cdn@unpkg"
      module:
        scope: "@dashkite"
        name: "joy"
        version: "0.7.0"
      path: "/src/index.js"

    unscoped:
      resolver: "node"
      module:
        scope: undefined
        name: "foo"
        version: "1.0.0"
      path: "/build/index.js"

    application:
      resolver: "application"
      path: "/src/index.js"

    root:
      scoped:
        resolver: "cdn@unpkg"
        module:
          scope: "@dashkite"
          name: "joy"
          version: "0.7.0"
        path: ""
      unscoped:
        resolver: "node"
        module:
          scope: undefined
          name: "foo"
          version: "1.0.0"
        path: ""

    bare:
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

export default ->
  [
    test "encodes and decodes descriptor without module", ->
      check.roundTrip Fixtures.descriptors.application,
        Fixtures.urls.application

    test "fails fast on malformed URLs", ->
      assert.throws -> AtlasURL.decode "not a url"

    test "encodes and decodes scoped module descriptor", ->
      check.roundTrip Fixtures.descriptors.scoped,
        Fixtures.urls.scoped

    test "encodes and decodes unscoped module descriptor", ->
      check.roundTrip Fixtures.descriptors.unscoped,
        Fixtures.urls.unscoped

    test "encodes and decodes scoped package-root descriptor", ->
      check.roundTrip Fixtures.descriptors.root.scoped,
        Fixtures.urls.root.scoped

    test "encodes and decodes unscoped package-root descriptor", ->
      check.roundTrip Fixtures.descriptors.root.unscoped,
        Fixtures.urls.root.unscoped

    test "encodes and decodes package-root descriptor with omitted path", ->
      check.roundTrip Fixtures.descriptors.bare,
        Fixtures.urls.root.unscoped,
        Fixtures.descriptors.root.unscoped
  ]