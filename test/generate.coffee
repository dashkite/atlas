import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import generate from "../src/generate"
import Path from "node:path"
import FS from "node:fs/promises"
import resolvers from "../src/presets/browser"

generateTestMap = ->
  entry = Path.resolve process.cwd(), "build/node/src/index.js"
  await FS.access entry
  options = { cwd: process.cwd() }
  generate entry, { options..., resolvers }

generateTestMapWithSource = ->
  source = Path.resolve process.cwd(), "build/node/src"
  await FS.access Path.join source, "index.js"
  options = { cwd: process.cwd(), source: "build/node/src" }
  generate "index.js", { options..., resolvers }

assertStructure = ( map ) ->
  assert map?, "ImportMap should exist"
  assert map.imports?, "ImportMap should have 'imports' block"
  assert map.scopes?, "ImportMap should have 'scopes' block"
  assert ( Object.keys map.imports ).length > 0,
    "Imports should be populated"

assertValidUrl = ( value ) ->
  if !value.startsWith "http"
    return
  url = new URL value
  assert !( url.pathname.includes "//" ),
    "URL pathname should not contain double slashes: #{value}"

assertUrls = ( map ) ->
  for key, value of map.imports
    assertValidUrl value
  for scope, mappings of map.scopes
    for key, value of mappings
      assertValidUrl value
  return

export default ->
  [
    test "generates an import map from an entry point using CDN resolver", ->
      map = await generateTestMap()
      assertStructure map
      assertUrls map

    test "generates an import map with entry relative to source", ->
      map = await generateTestMapWithSource()
      assertStructure map
      assertUrls map
  ]