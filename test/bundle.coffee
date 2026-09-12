import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import bundle from "../src/bundle"
import FS from "node:fs/promises"
import Path from "node:path"
import OS from "node:os"
import JSZip from "jszip"

export default ->
  [
    test "creates a bundle zip with entry and package.json", ->
      tempDir = await FS.mkdtemp Path.join(OS.tmpdir(), "atlas-bundle-")
      
      entryPath = Path.join tempDir, "index.js"
      await FS.writeFile entryPath, "import { foo } from './foo.js';\nexport const main = () => { console.log(foo); };"
      
      fooPath = Path.join tempDir, "foo.js"
      await FS.writeFile fooPath, "export const foo = 'hello';"
      
      pkgPath = Path.join tempDir, "package.json"
      await FS.writeFile pkgPath, JSON.stringify({ name: "test-pkg", version: "1.0.0" })
      
      try
        zipBuffer = await bundle entryPath, { cwd: tempDir, root: tempDir }
        assert Buffer.isBuffer zipBuffer
        
        zip = await JSZip.loadAsync zipBuffer
        
        # Verify files are in the zip
        files = Object.keys zip.files
        
        assert files.includes "index.js"
        assert files.includes "package.json"
        
        content = await zip.file("index.js").async("string")
        assert content == "import { foo } from './foo.js';\nexport const main = () => { console.log(foo); };"
      finally
        await FS.rm tempDir, { recursive: true, force: true }
  ]
