# Technical Notes

### Import Maps

Import maps are a native browser technology that allows developers to control how JavaScript modules resolve import specifiers. They are fundamentally important because they eliminate the need for complex build-time bundlers when resolving bare module specifiers (e.g., `import _ from "lodash"`). Instead of running a bundler to rewrite these specifiers to static URLs, an import map instructs the browser exactly where to fetch the requested module.

This capability effectively transforms import maps into a universal package management service directly inside the browser. By centralizing the resolution logic, multiple independently deployed applications or micro-frontends can share common dependencies dynamically, leading to smaller payloads and simplified workflows without losing the convenience of standard Node.js-style module resolution.

For more detailed reading on import maps as a technology, consult the following resources:
- [MDN: Import map JSON representation](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/script/type/importmap#import_map_json_representation)
- [HTML Specification: Import maps](https://html.spec.whatwg.org/multipage/webappapis.html#import-map)
- [Web.dev: Import maps in all modern browsers](https://web.dev/blog/import-maps-in-all-modern-browsers)

### Dependency Analysis with esbuild

Before Atlas can generate an import map or application bundle, it needs a complete picture of the module graph. Atlas delegates this dependency analysis to [esbuild](https://esbuild.github.io/).

The performance of esbuild makes it extremely efficient at resolving the version-specific dependency tree. Rather than emitting a bundled file, `analyze` runs a mock build (targeting `/dev/null` with `metafile: true`) using `absWorkingDir: Path.resolve(options.cwd)` and resolving each input entry point against `options.source` (`Path.resolve(cwd, options.source ? ".")`). By inspecting the `inputs` and `imports` within the `metafile`, Atlas discovers all modules, their import specifiers, and their exact file paths relative to `cwd`.

### Directory Options: `cwd`, `source`, and `root`

Atlas strictly separates pipeline execution directories from resolver configuration roots:

1. **`options.cwd` (Target Package Root)**:
   - Accepted by `analyze`, `ingest`, `generate`, and `bundle` (defaulting to `process.cwd()`).
   - Defines the target package root directory where `package.json` and `node_modules` live.
   - Passed to `esbuild` as `absWorkingDir`, used by `ingest` to resolve and `stat` dependency files, and used by `bundle` to read the root `package.json` and compute archive-relative entry paths.
2. **`options.source` (Entry Point Base Directory)**:
   - Accepted by `analyze`, `generate`, and `bundle` (defaulting to `options.cwd`, resolved via `Path.resolve(cwd, options.source ? ".")`).
   - Convenience option specifying the directory from which input `entries` are resolved (`Path.resolve(source, entry)`).
   - **Input Entry Resolution Only**: `options.source` only affects how input `entries` are located on disk. All intra-application module paths and ZIP archive paths remain relative to `options.cwd`, ensuring that `package.json` `#` subpath imports, `../` relative imports outside `source`, and AWS Lambda handler paths remain consistent with the package root.
3. **`config.root` (Resolver Base Directory / Workspace Boundary)**:
   - Accepted by `Application.make`, `Node.make`, and `Local.make` at resolver instantiation time.
   - Used by `resolve(atlasUrl)` to map canonical `atlas://` URLs back to `file://` URLs on disk, and used by `LocalResolver` as the fallback base directory when `context.cwd` is not provided.

### Ingestion and Physical Deduplication

The `ingest` stage consumes the dependency reactor from `analyze` and constructs a `ModuleGraph`:
- **Inode Deduplication**: Because package managers like `pnpm` create symlinked virtual stores pointing to hard-linked files, `esbuild` can emit multiple paths that refer to the same physical file on disk. `ingest` checks `(await FS.stat(Path.resolve(cwd, path))).ino` and caches the encoded `atlas://` URL by inode so identical files always collapse to a single vertex in `ModuleGraph`.
- **Canonical `atlas://` URLs**: Each dependency is matched against a composite Meta Resolver (`Resolvers.Registry.make(keys)`) with `context = { source: target.source.path, cwd }` and encoded into a canonical `atlas://` URL (`atlas://application/...`, `atlas://local@key/...`, `atlas://node/...`, or `atlas://cdn@key/...`).

### Functor Pipelines

Once `ingest` produces a `ModuleGraph`, Atlas applies category-theoretic functor pipelines depending on the target output:

#### 1. Import Map Generation (`generate`)
1. **`baseline` (`functors/baseline`)**: Projects the `ModuleGraph` into a baseline scope trie containing exact module-scoped mappings.
2. **`compact` (`functors/compaction`)**: Safely lifts common mappings toward parent scopes or the root `imports` block without introducing shadowing conflicts.
3. **`compress` (`functors/compression`)**: Collapses file-level mappings sharing common directory prefixes into trailing-slash directory prefix mappings.
4. **`resolve` (`functors/resolution`)**: Translates canonical `atlas://` target and scope URLs into runtime URLs (`https://...` or `file://...`) via `metaResolver.resolve`.
5. **`serialize` (`functors/serialization`)**: Formats the resolved trie into a standard WHATWG `{ imports, scopes }` JSON object.

#### 2. Application Bundling (`bundle`)
1. **`quotient` (`functors/quotient`)**: Contracts intra-package edges (`./`, `../`, `#`) so each package version forms a single strongly connected component in a `ComponentGraph`.
2. **`compile` (`functors/compiler`)**: Embeds the `ComponentGraph` into a hierarchical `TreeIndex` (performing topological hoisting/compaction by default when `options.compact` is enabled, and isolating conflicting versions into nested scopes).
3. **`resolve` (`functors/resolver`)**: Projects the `TreeIndex` and `ModuleGraph` into a physical `Map<destinationPath, atlasUrl>` placing external and local packages into their resolved `node_modules/` hierarchy.
4. **`BundleArchive`**: Packages the entry points (at `Path.relative(cwd, Path.resolve(source, entry))`), the root `package.json`, all resolved dependency files, and their nearest `package.json` manifests into a compressed ZIP `Buffer`.

### The Shadowing Problem

The primary challenge in both import map compaction and bundle tree hoisting is avoiding accidental shadowing. Because browsers (for import maps) and Node.js (for `node_modules` resolution) resolve specifiers by matching the most specific enclosing scope first and stopping there, lifting a binding to a broader parent scope can capture descendant modules that require a different version of the same specifier.

To prevent shadowing, Atlas verifies candidate promotions against all descendant scopes in the trie or tree index, committing a lift only when every module continues to resolve to its exact required target.
