import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import bundle from "../src/bundle"
import FS from "node:fs/promises"
import Path from "node:path"
import OS from "node:os"
import JSZip from "jszip"

createDirectory = ( prefix, write ) ->
  directory = await FS.mkdtemp Path.join OS.tmpdir(), prefix
  await write directory
  directory

Fixtures =
  entry:
    "import { foo } from './foo.js';\n" +
    "export const main = () => { console.log(foo); };"

  write: ( directory ) ->
    await FS.writeFile ( Path.join directory, "index.js" ), Fixtures.entry
    await FS.writeFile ( Path.join directory, "foo.js" ),
      "export const foo = 'hello';"
    FS.writeFile ( Path.join directory, "package.json" ),
      JSON.stringify { name: "test-pkg", version: "1.0.0" }

  create: ->
    createDirectory "atlas-bundle-", Fixtures.write

Nested =
  write: ( directory ) ->
    source = Path.join directory, "src", "shell"
    await FS.mkdir source, { recursive: true }
    await FS.writeFile ( Path.join source, "index.js" ), Fixtures.entry
    await FS.writeFile ( Path.join source, "foo.js" ),
      "export const foo = 'hello';"
    FS.writeFile ( Path.join directory, "package.json" ),
      JSON.stringify { name: "test-pkg", version: "1.0.0" }

  create: ->
    createDirectory "atlas-bundle-source-", Nested.write

NoManifest =
  entry: "export const main = () => { console.log('hello'); };"

  write: ( directory ) ->
    FS.writeFile ( Path.join directory, "index.js" ), NoManifest.entry

  create: ->
    createDirectory "atlas-bundle-no-manifest-", NoManifest.write

Zip =
  load: ( buffer ) ->
    assert Buffer.isBuffer buffer
    JSZip.loadAsync buffer

  hasFile: ( zip, path ) ->
    ( Object.keys zip.files ).includes path

  readText: ( zip, path ) ->
    ( zip.file path ).async "string"

  verify: ( buffer ) ->
    zip = await Zip.load buffer
    assert Zip.hasFile zip, "index.js"
    assert Zip.hasFile zip, "package.json"
    assert.equal ( await Zip.readText zip, "index.js" ), Fixtures.entry

  nested: ( buffer ) ->
    zip = await Zip.load buffer
    assert Zip.hasFile zip, "src/shell/index.js"
    assert Zip.hasFile zip, "src/shell/foo.js"
    assert Zip.hasFile zip, "package.json"
    assert.equal ( await Zip.readText zip, "src/shell/index.js" ),
      Fixtures.entry

  noManifest: ( buffer ) ->
    zip = await Zip.load buffer
    assert Zip.hasFile zip, "index.js"
    assert !( Zip.hasFile zip, "package.json" )
    assert.equal ( await Zip.readText zip, "index.js" ), NoManifest.entry

cleanup = ( directory ) ->
  FS.rm directory, { recursive: true, force: true }

Cases =
  bundle: ->
    directory = await Fixtures.create()
    try
      await Zip.verify await bundle ( Path.join directory, "index.js" ),
        cwd: directory
    finally
      await cleanup directory

  relative: ->
    directory = await Fixtures.create()
    try
      await Zip.verify await bundle "index.js", cwd: directory
    finally
      await cleanup directory

  source: ->
    directory = await Nested.create()
    try
      await Zip.nested await bundle "index.js",
        cwd: directory
        source: "src/shell"
    finally
      await cleanup directory

  noManifest: ->
    directory = await NoManifest.create()
    try
      await Zip.noManifest await bundle "index.js", cwd: directory
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