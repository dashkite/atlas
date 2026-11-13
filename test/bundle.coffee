import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Path from "node:path"
import bundle from "../src/bundle"
import Fixtures from "./helpers/fixtures"
import Archive from "./helpers/archive"

export default ->
  [
    test "creates a bundle zip with entry and package.json", ->
      await Fixtures.run Fixtures.standard, ( directory ) ->
        buffer = await bundle ( Path.join directory, "index.js" ),
          cwd: directory
        await Archive.standard buffer

    test "creates a bundle zip with relative entry and cwd", ->
      await Fixtures.run Fixtures.standard, ( directory ) ->
        buffer = await bundle "index.js", cwd: directory
        await Archive.standard buffer

    test "creates a bundle zip with entry relative to source", ->
      await Fixtures.run Fixtures.nested, ( directory ) ->
        buffer = await bundle "index.js",
          cwd: directory
          source: "src/shell"
        await Archive.nested buffer

    test "creates a bundle zip when cwd has no package.json", ->
      await Fixtures.run Fixtures.bare, ( directory ) ->
        buffer = await bundle "index.js", cwd: directory
        await Archive.bare buffer

    test "rejects non-boolean compact option at boundary", ->
      await assert.rejects ->
        Promise.resolve().then -> bundle "index.js", compact: "invalid"
  ]
