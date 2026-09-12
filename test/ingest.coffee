import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ingest from "../src/ingest"
import ModuleGraph from "../src/categories/module-graph"
import FS from "node:fs/promises"
import Path from "node:path"
import OS from "node:os"

export default ->
  [
    test "deduplicates physical paths using inodes", ->
      # Create a dummy file and a hardlink to it to simulate PNPM virtual store behavior
      tempDir = await FS.mkdtemp Path.join(OS.tmpdir(), "atlas-ingest-")
      
      originalPath = Path.join tempDir, "original.js"
      await FS.writeFile originalPath, "export const x = 1;"
      
      hardLinkPath = Path.join tempDir, "linked.js"
      await FS.link originalPath, hardLinkPath

      # Create fake esbuild dependency entries
      dependencies = [
        {
          import:
            specifier: "a"
            scope: null
          source:
            path: originalPath
        },
        {
          import:
            specifier: "b"
            scope: null
          source:
            path: hardLinkPath
        }
      ]

      options =
        cwd: tempDir
        local:
          patterns: [] # Force fallback to other resolvers or fail
          
      # Let's write a mock resolver that just uses the filename to prove they map differently if not for inodes
      # Actually, wait, if we just use a default resolver, it will map to something based on path.
      # To strictly test inode caching, we can inject a mock resolver.
      mockResolver =
        match: -> true
        encode: (item) -> "atlas://mock/" + Path.basename(item.source.path)

      graph = await ingest dependencies, { cwd: tempDir, resolvers: [ mockResolver ] }
      
      # Since originalPath and hardLinkPath have the SAME inode, ingest should cache the first one
      # and reuse its URL ("atlas://mock/original.js") for the second one, NEVER calling the 
      # resolver for "linked.js".
      
      urls = Array.from graph.sources.keys()
      
      assert urls.includes "atlas://mock/original.js"
      assert !(urls.includes "atlas://mock/linked.js")
      
      # Clean up
      await FS.rm tempDir, { recursive: true, force: true }
  ]
