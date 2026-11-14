import FS from "node:fs/promises"
import Path from "node:path"
import OS from "node:os"

Sources =
  entry:
    "import { foo } from './foo.js';\n" +
    "export const main = () => { console.log(foo); };"
  dependency: "export const foo = 'hello';"
  bare: "export const main = () => { console.log('hello'); };"
  manifest: JSON.stringify name: "test-pkg", version: "1.0.0"
  externalEntry:
    "import { dep } from '@scope/dep';\n" +
    "export const main = () => { console.log(dep); };"
  externalDependency: "export const dep = 'hello';"
  externalManifest: JSON.stringify
    name: "@scope/dep"
    version: "1.0.0"
    main: "index.js"

writeModule = ( directory ) ->
  await FS.writeFile ( Path.join directory, "index.js" ), Sources.entry
  await FS.writeFile ( Path.join directory, "foo.js" ), Sources.dependency

writePackage = ( directory ) ->
  pkg = Path.join directory, "node_modules", "@scope", "dep"
  await FS.mkdir pkg, recursive: true
  await FS.writeFile ( Path.join pkg, "index.js" ),
    Sources.externalDependency
  await FS.writeFile ( Path.join pkg, "package.json" ),
    Sources.externalManifest

Fixtures =
  sources: Sources

  standard: ( directory ) ->
    await writeModule directory
    manifest = Path.join directory, "package.json"
    await FS.writeFile manifest, Sources.manifest

  nested: ( directory ) ->
    source = Path.join directory, "src", "shell"
    await FS.mkdir source, recursive: true
    await writeModule source
    manifest = Path.join directory, "package.json"
    await FS.writeFile manifest, Sources.manifest

  bare: ( directory ) ->
    await FS.writeFile ( Path.join directory, "index.js" ), Sources.bare

  external: ( directory ) ->
    await FS.writeFile ( Path.join directory, "index.js" ),
      Sources.externalEntry
    manifest = Path.join directory, "package.json"
    await FS.writeFile manifest, Sources.manifest
    await writePackage directory

  run: ( setup, action ) ->
    directory = await FS.mkdtemp Path.join OS.tmpdir(), "atlas-bundle-"
    try
      await setup directory
      await action directory
    finally
      await FS.rm directory, recursive: true, force: true

export default Fixtures
