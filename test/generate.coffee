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
      foundJszip = false
      foundScoped = false
      
      for key, value of importMap.imports
        if key == "jszip"
          assert value.startsWith("https://unpkg.com/jszip@"), "URL should start with unpkg jszip with version"
          assert value.endsWith("/lib/index.js"), "URL should end with /lib/index.js"
          foundJszip = true
          
        if key.startsWith("@dashkite/") and value.startsWith("https://")
          assert value.startsWith("https://unpkg.com/@dashkite/"), "URL should start with unpkg @dashkite scope"
          assert not value.includes("//dashkite/"), "URL must not contain double slashes"
          foundScoped = true
          
      assert foundJszip, "Should find jszip in the import map"
      assert foundScoped, "Should find a @dashkite scoped package in the import map"
  ]
