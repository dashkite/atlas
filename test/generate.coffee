import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import generate from "../src/generate"
import resolvers from "../src/presets/browser"

assertStructure = ( map ) ->
  assert map?, "ImportMap should exist"
  assert map.imports?, "ImportMap should have 'imports' block"
  assert map.scopes?, "ImportMap should have 'scopes' block"
  assert ( Object.keys map.imports ).length > 0,
    "Imports should be populated"

assertURL = ( value ) ->
  if value.startsWith "http"
    url = new URL value
    assert !( url.pathname.includes "//" ),
      "URL pathname should not contain double slashes: #{value}"
    assert !( value.includes "//src" )
  return

assertURLs = ( map ) ->
  for key, value of map.imports
    assertURL value
  for scope, mappings of map.scopes
    for key, value of mappings
      assertURL value
  return

export default ->
  [
    test "generates an import map from an entry point using CDN resolver", ->
      map = await generate [ "build/node/src/index.js" ],
        cwd: process.cwd()
        resolvers
      assertStructure map
      assertURLs map

    test "generates an import map with entry relative to source", ->
      map = await generate [ "index.js" ],
        cwd: process.cwd()
        source: "build/node/src"
        resolvers
      assertStructure map
      assertURLs map

    test "rejects invalid entries at boundary", ->
      await assert.rejects -> await generate ""
      await assert.rejects -> await generate []
      await assert.rejects -> await generate [ "" ]
      await assert.rejects -> await generate null
  ]
