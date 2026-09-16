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
      
      # Verify all generated HTTP URLs
      for key, value of importMap.imports
        # Local paths or bare specifiers might not be full URLs, but if it starts with http, parse it
        if value.startsWith "http"
          url = new URL value
          assert not url.pathname.includes("//"), "URL pathname should not contain double slashes: #{value}"
          
      if importMap.scopes?
        for scope, mappings of importMap.scopes
          for key, value of mappings
            if value.startsWith "http"
              url = new URL value
              assert not url.pathname.includes("//"), "URL pathname should not contain double slashes: #{value}"
  ]
