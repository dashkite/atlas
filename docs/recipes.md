# Usage Guides

## Generating a browser import map

This task involves generating a compacted WHATWG import map for a browser application using the built-in browser resolver preset.

```coffeescript
import { generate } from "@dashkite/atlas"
import browserPreset from "@dashkite/atlas/presets/browser"

map = await generate "index.js",
  cwd: "/path/to/app"
  source: "build/browser/src"
  resolvers: browserPreset
```

1. We import `generate` from `@dashkite/atlas` and the default browser resolver key list (`["application", "local@default", "cdn@unpkg"]`) from `@dashkite/atlas/presets/browser`.
2. We specify `cwd` as the root of the target package (where `package.json` and `node_modules` live) and `source` as `"build/browser/src"` (relative to `cwd`).
3. `generate` resolves `"index.js"` against `source`, analyzes its dependency tree relative to `cwd`, ingests and deduplicates all modules into a `ModuleGraph`, and runs the baseline, compaction, compression, resolution, and serialization functors to produce `{ imports, scopes }`.

## Bundling an AWS Lambda or Node.js entry point

This task involves bundling one or more compiled entry points from a nested source directory into a self-contained ZIP buffer while preserving paths relative to the package root (`cwd`).

```coffeescript
import { bundle } from "@dashkite/atlas"

storageArchive = await bundle "storage.js",
  cwd: "/path/to/cerulean"
  source: "build/node/src/shell"
```

1. `bundle` resolves `"storage.js"` relative to `source` (`/path/to/cerulean/build/node/src/shell/storage.js`).
2. `esbuild` analyzes the dependency graph with `absWorkingDir` set to `cwd` (`/path/to/cerulean`).
3. Inside the generated ZIP buffer, the entry point is stored at `build/node/src/shell/storage.js` (relative to `cwd`), the package's root `package.json` is placed at `package.json`, and external/local dependencies are placed in their resolved `node_modules/` or `local/` locations alongside their respective `package.json` manifests.

## Registering a custom Local or CDN resolver

This task involves configuring a custom `Local` workspace resolver (with a workspace `root` distinct from the target package `cwd`) or a custom `CDN` resolver in `Resolvers.Registry`.

```coffeescript
import { bundle, generate, Resolvers } from "@dashkite/atlas"

# Register a Local resolver for a metarepo workspace root
Resolvers.Registry.register "local@central-park",
  Resolvers.Local.make
    root: "/path/to/central-park"
    patterns: [ "**/.tempo/repos/**/*", "../**/*" ]

# Bundle a package inside the metarepo using the custom resolver key
zipBuffer = await bundle "gateway.js",
  cwd: "/path/to/central-park/.tempo/repos/cerulean"
  source: "build/node/src/shell"
  resolvers: [ "application", "local@central-park", "node" ]

# Or generate an import map using a specific CDN preset key ("cdn@jsdelivr")
map = await generate "index.js",
  cwd: "/path/to/central-park/.tempo/repos/cerulean"
  source: "build/browser/src"
  resolvers: [ "application", "local@central-park", "cdn@jsdelivr" ]
```

1. Resolver instances are configured once via `.make({ root, patterns })` (or `.make({ template })` for `CDN`) and registered under a named key in `Resolvers.Registry`.
2. Pipeline functions (`generate` and `bundle`) receive an ordered array of registered resolver keys in `options.resolvers`, keeping static resolver configuration (`root`) cleanly separated from pipeline execution options (`cwd` and `source`).

## Inspecting the dependency graph with `analyze` and `ingest`

This task involves running the discovery and ingestion stages directly to inspect the deduplicated `ModuleGraph`.

```coffeescript
import { analyze, ingest } from "@dashkite/atlas"
import nodePreset from "@dashkite/atlas/presets/node"

options =
  cwd: "/path/to/app"
  source: "build/node/src"
  resolvers: nodePreset

dependencies = analyze [ "index.js" ], options
graph = await ingest dependencies, options

console.log Array.from graph.sources.entries()
```

1. `analyze` runs `esbuild` on `"index.js"` (resolved against `options.source`) with `absWorkingDir` set to `options.cwd`, returning an async generator of dependency edges.
2. `ingest` consumes the async generator, deduplicates physical files by inode (`fs.stat(path).ino`), encodes each module into a canonical `atlas://` URL using the configured `resolvers`, and returns the `ModuleGraph`.
