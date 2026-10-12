import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import generate from "../src/generate"
import Path from "node:path"
import FS from "node:fs/promises"
import browserKeys from "../src/presets/browser"

generateTestMap = ->
  entryPath = Path.resolve process.cwd(), "build/node/src/index.js"
  await FS.access entryPath
  options = { cwd: process.cwd() }
  generate entryPath, { options..., resolvers: browserKeys }

assertStructure = ( importMap ) ->
  assert importMap?, "ImportMap should exist"
  assert importMap.imports?, "ImportMap should have 'imports' block"
  assert importMap.scopes?, "ImportMap should have 'scopes' block"
  assert ( Object.keys importMap.imports ).length > 0,
    "Imports should be populated"

assertValidUrl = ( value ) ->
  if !value.startsWith "http"
    return
  url = new URL value
  assert !( url.pathname.includes "//" ),
    "URL pathname should not contain double slashes: #{value}"

assertUrls = ( importMap ) ->
  for key, value of importMap.imports
    assertValidUrl value
  for scope, mappings of importMap.scopes
    for key, value of mappings
      assertValidUrl value
  return

export default ->
  [
    test "generates an import map from an entry point using CDN resolver", ->
      importMap = await generateTestMap()
      assertStructure importMap
      assertUrls importMap
  ]