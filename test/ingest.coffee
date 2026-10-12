import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ingest from "../src/ingest"
import FS from "node:fs/promises"
import Path from "node:path"
import OS from "node:os"
import { Registry } from "../src/resolvers/index"

setupFileSystem = ->
  directory = await FS.mkdtemp Path.join OS.tmpdir(), "atlas-ingest-"
  original = Path.join directory, "original.js"
  await FS.writeFile original, "export const x = 1;"
  linked = Path.join directory, "linked.js"
  await FS.link original, linked
  { directory, original, linked }

createDependencies = (original, linked) ->
  [
    { import: { specifier: "a", scope: null }, source: { path: original } }
    { import: { specifier: "b", scope: null }, source: { path: linked } }
  ]

setupMockResolver = ->
  Registry.register "mock",
    match: -> true
    encode: (descriptor) ->
      "atlas://mock/mock@1.0.0/" + Path.basename descriptor.path
    decode: (_url) ->
      { resolver: "mock", module: { name: "mock", version: "1.0.0" } }

assertDeduplicated = (graph) ->
  urls = Array.from graph.sources.keys()
  assert urls.includes "atlas://mock/mock@1.0.0/original.js"
  assert !(urls.includes "atlas://mock/mock@1.0.0/linked.js")

cleanup = (directory) ->
  FS.rm directory, recursive: true, force: true

export default ->
  [
    test "deduplicates physical paths using inodes", ->
      setupMockResolver()
      { directory, original, linked } = await setupFileSystem()
      dependencies = createDependencies original, linked
      graph = await ingest dependencies,
        cwd: directory
        resolvers: [ "mock" ]
      assertDeduplicated graph
      cleanup directory
  ]