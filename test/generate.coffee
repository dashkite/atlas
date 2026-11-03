import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import generate from "../src/generate"
import resolvers from "../src/presets/browser"

Fixtures =
  default: ->
    generate [ "build/node/src/index.js" ],
      cwd: process.cwd()
      resolvers

  withSource: ->
    generate [ "index.js" ],
      cwd: process.cwd()
      source: "build/node/src"
      resolvers

Assert =
  structure: ( map ) ->
    assert map?, "ImportMap should exist"
    assert map.imports?, "ImportMap should have 'imports' block"
    assert map.scopes?, "ImportMap should have 'scopes' block"
    assert ( Object.keys map.imports ).length > 0,
      "Imports should be populated"

  url: ( value ) ->
    if value.startsWith "http"
      url = new URL value
      assert !( url.pathname.includes "//" ),
        "URL pathname should not contain double slashes: #{value}"
      assert !( value.includes "//src" )
    return

  urls: ( map ) ->
    for key, value of map.imports
      Assert.url value
    for scope, mappings of map.scopes
      for key, value of mappings
        Assert.url value
    return

export default ->
  [
    test "generates an import map from an entry point using CDN resolver", ->
      map = await Fixtures.default()
      Assert.structure map
      Assert.urls map

    test "generates an import map with entry relative to source", ->
      map = await Fixtures.withSource()
      Assert.structure map
      Assert.urls map
  ]