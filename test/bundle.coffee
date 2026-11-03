import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import bundle from "../src/bundle"
import FS from "node:fs/promises"
import Path from "node:path"
import OS from "node:os"
import JSZip from "jszip"

entrySource =
  "import { foo } from './foo.js';\n" +
  "export const main = () => { console.log(foo); };"

Fixtures =
  write: ( directory ) ->
    await FS.writeFile ( Path.join directory, "index.js" ), entrySource
    await FS.writeFile ( Path.join directory, "foo.js" ),
      "export const foo = 'hello';"
    FS.writeFile ( Path.join directory, "package.json" ),
      JSON.stringify { name: "test-pkg", version: "1.0.0" }

  create: ->
    directory = await FS.mkdtemp Path.join OS.tmpdir(), "atlas-bundle-"
    await Fixtures.write directory
    directory

Nested =
  write: ( directory ) ->
    source = Path.join directory, "src", "shell"
    await FS.mkdir source, { recursive: true }
    await FS.writeFile ( Path.join source, "index.js" ), entrySource
    await FS.writeFile ( Path.join source, "foo.js" ),
      "export const foo = 'hello';"
    FS.writeFile ( Path.join directory, "package.json" ),
      JSON.stringify { name: "test-pkg", version: "1.0.0" }

  create: ->
    directory = await FS.mkdtemp Path.join OS.tmpdir(), "atlas-bundle-source-"
    await Nested.write directory
    directory

NoManifest =
  entry: "export const main = () => { console.log('hello'); };"

  write: ( directory ) ->
    FS.writeFile ( Path.join directory, "index.js" ), NoManifest.entry

  create: ->
    prefix = Path.join OS.tmpdir(), "atlas-bundle-no-manifest-"
    directory = await FS.mkdtemp prefix
    await NoManifest.write directory
    directory

Zip =
  verify: ( buffer ) ->
    assert Buffer.isBuffer buffer
    zip = await JSZip.loadAsync buffer
    files = Object.keys zip.files
    assert files.includes "index.js"
    assert files.includes "package.json"
    content = await ( zip.file "index.js" ).async "string"
    assert content == entrySource

  nested: ( buffer ) ->
    assert Buffer.isBuffer buffer
    zip = await JSZip.loadAsync buffer
    files = Object.keys zip.files
    assert files.includes "src/shell/index.js"
    assert files.includes "src/shell/foo.js"
    assert files.includes "package.json"
    content = await ( zip.file "src/shell/index.js" ).async "string"
    assert content == entrySource

  noManifest: ( buffer ) ->
    assert Buffer.isBuffer buffer
    zip = await JSZip.loadAsync buffer
    files = Object.keys zip.files
    assert files.includes "index.js"
    assert !files.includes "package.json"
    content = await ( zip.file "index.js" ).async "string"
    assert content == NoManifest.entry

cleanup = ( directory ) ->
  FS.rm directory, { recursive: true, force: true }

Cases =
  bundle: ->
    directory = await Fixtures.create()
    try
      entry = Path.join directory, "index.js"
      buffer = await bundle entry, { cwd: directory }
      await Zip.verify buffer
    finally
      await cleanup directory

  relative: ->
    directory = await Fixtures.create()
    try
      buffer = await bundle "index.js", { cwd: directory }
      await Zip.verify buffer
    finally
      await cleanup directory

  source: ->
    directory = await Nested.create()
    try
      buffer = await bundle "index.js", { cwd: directory, source: "src/shell" }
      await Zip.nested buffer
    finally
      await cleanup directory

  noManifest: ->
    directory = await NoManifest.create()
    try
      buffer = await bundle "index.js", { cwd: directory }
      await Zip.noManifest buffer
    finally
      await cleanup directory

export default ->
  [
    test "creates a bundle zip with entry and package.json", Cases.bundle
    test "creates a bundle zip with relative entry and cwd",
      Cases.relative
    test "creates a bundle zip with entry relative to source",
      Cases.source
    test "creates a bundle zip when cwd has no package.json",
      Cases.noManifest
  ]