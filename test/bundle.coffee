import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import bundle from "../src/bundle"
import FS from "node:fs/promises"
import Path from "node:path"
import OS from "node:os"
import JSZip from "jszip"

ENTRY_SOURCE =
  "import { foo } from './foo.js';\n" +
  "export const main = () => { console.log(foo); };"

writeFixtures = ( directory ) ->
  await FS.writeFile ( Path.join directory, "index.js" ), ENTRY_SOURCE
  await FS.writeFile ( Path.join directory, "foo.js" ),
    "export const foo = 'hello';"
  FS.writeFile ( Path.join directory, "package.json" ),
    JSON.stringify { name: "test-pkg", version: "1.0.0" }

createFixtures = ->
  directory = await FS.mkdtemp Path.join OS.tmpdir(), "atlas-bundle-"
  await writeFixtures directory
  directory

verifyZip = ( buffer ) ->
  assert Buffer.isBuffer buffer
  zip = await JSZip.loadAsync buffer
  files = Object.keys zip.files
  assert files.includes "index.js"
  assert files.includes "package.json"
  content = await ( zip.file "index.js" ).async "string"
  assert content == ENTRY_SOURCE

cleanup = ( directory ) ->
  FS.rm directory, { recursive: true, force: true }

writeNestedFixtures = ( directory ) ->
  source = Path.join directory, "src", "shell"
  await FS.mkdir source, { recursive: true }
  await FS.writeFile ( Path.join source, "index.js" ), ENTRY_SOURCE
  await FS.writeFile ( Path.join source, "foo.js" ),
    "export const foo = 'hello';"
  FS.writeFile ( Path.join directory, "package.json" ),
    JSON.stringify { name: "test-pkg", version: "1.0.0" }

createNestedFixtures = ->
  directory = await FS.mkdtemp Path.join OS.tmpdir(), "atlas-bundle-source-"
  await writeNestedFixtures directory
  directory

verifyNestedZip = ( buffer ) ->
  assert Buffer.isBuffer buffer
  zip = await JSZip.loadAsync buffer
  files = Object.keys zip.files
  assert files.includes "src/shell/index.js"
  assert files.includes "src/shell/foo.js"
  assert files.includes "package.json"
  content = await ( zip.file "src/shell/index.js" ).async "string"
  assert content == ENTRY_SOURCE

testBundle = ->
  directory = await createFixtures()
  try
    entry = Path.join directory, "index.js"
    buffer = await bundle entry, { cwd: directory }
    await verifyZip buffer
  finally
    await cleanup directory

testRelativeEntry = ->
  directory = await createFixtures()
  try
    buffer = await bundle "index.js", { cwd: directory }
    await verifyZip buffer
  finally
    await cleanup directory

testSourceDirectory = ->
  directory = await createNestedFixtures()
  try
    buffer = await bundle "index.js", { cwd: directory, source: "src/shell" }
    await verifyNestedZip buffer
  finally
    await cleanup directory

export default ->
  [
    test "creates a bundle zip with entry and package.json", testBundle
    test "creates a bundle zip with relative entry and cwd",
      testRelativeEntry
    test "creates a bundle zip with entry relative to source",
      testSourceDirectory
  ]