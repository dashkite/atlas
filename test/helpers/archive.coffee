import assert from "@dashkite/assert"
import JSZip from "jszip"
import Fixtures from "./fixtures"

Archive =
  load: ( buffer ) ->
    assert Buffer.isBuffer buffer
    JSZip.loadAsync buffer

  hasFile: ( zip, path ) ->
    ( Object.keys zip.files ).includes path

  readText: ( zip, path ) ->
    ( zip.file path ).async "string"

  standard: ( buffer ) ->
    zip = await Archive.load buffer
    assert Archive.hasFile zip, "index.js"
    assert Archive.hasFile zip, "package.json"
    assert.equal ( await Archive.readText zip, "index.js" ),
      Fixtures.sources.entry

  nested: ( buffer ) ->
    zip = await Archive.load buffer
    assert Archive.hasFile zip, "src/shell/index.js"
    assert Archive.hasFile zip, "src/shell/foo.js"
    assert Archive.hasFile zip, "package.json"
    assert.equal ( await Archive.readText zip, "src/shell/index.js" ),
      Fixtures.sources.entry

  bare: ( buffer ) ->
    zip = await Archive.load buffer
    assert Archive.hasFile zip, "index.js"
    assert !( Archive.hasFile zip, "package.json" )
    assert.equal ( await Archive.readText zip, "index.js" ),
      Fixtures.sources.bare

  external: ( buffer ) ->
    zip = await Archive.load buffer
    assert Archive.hasFile zip, "index.js"
    assert Archive.hasFile zip, "package.json"
    assert Archive.hasFile zip, "node_modules/@scope/dep/index.js"
    assert Archive.hasFile zip, "node_modules/@scope/dep/package.json"
    assert.equal ( await Archive.readText zip, "index.js" ),
      Fixtures.sources.externalEntry
    assert.equal (
      await Archive.readText zip, "node_modules/@scope/dep/index.js"
    ), Fixtures.sources.externalDependency
    assert.equal (
      await Archive.readText zip, "node_modules/@scope/dep/package.json"
    ), Fixtures.sources.externalManifest

export default Archive
