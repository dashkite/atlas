import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import generate from "../src/generate"
import Path from "node:path"
import FS from "node:fs/promises"
import CDN from "../src/resolvers/cdn"
import nodePreset from "../src/presets/node"
import browserKeys from "../src/presets/browser"

export default ->
  [
    test "generates an import map from an entry point using CDN resolver", ->
      # Point to the compiled package entry point.
      entryPath = Path.resolve process.cwd(), "build/node/src/index.js"
      await FS.access entryPath
      
      options = { cwd: process.cwd(), root: process.cwd() }
      
      resolvers = browserKeys
      
      importMap = await generate entryPath, { options..., resolvers }
      
      # Assert structural validity of WHATWG ImportMap
      assert importMap?, "ImportMap should exist"
      assert importMap.imports?, "ImportMap should have 'imports' block"
      assert importMap.scopes?, "ImportMap should have 'scopes' block"
      assert Object.keys(importMap.imports).length > 0, "Imports should be populated"
      
      # Verify CDN HTTP URLs are generated correctly for external packages
      # We check a specific package, e.g. jszip, which is imported by bundle.coffee
      found = false
      for key, value of importMap.imports
        if key == "jszip"
          # It should resolve to the exact formatted URL structure
          assert value.startsWith("https://unpkg.com/jszip@"), "URL should start with unpkg jszip with version"
          assert value.endsWith("/lib/index.js"), "URL should end with /lib/index.js"
          found = true
          break
          
      assert found, "Should find jszip in the import map"
  ]
