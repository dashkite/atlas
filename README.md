# Atlas

*Generate JavaScript import maps and Node/Lambda application bundles from a given set of entry points.*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Atlas is a library that analyzes module dependencies and transforms them into either compacted, optimized JavaScript import maps (`generate`) or self-contained ZIP archives suitable for Node.js and AWS Lambda execution (`bundle`). It provides a configurable system of resolvers (`Application`, `Local`, `Node`, and `CDN`) for translating dependencies between physical paths, canonical `atlas://` URLs, and target runtime URLs.

## Features

- Fast dependency discovery using `esbuild` to resolve version-specific dependency trees.
- Physical deduplication via inode caching during dependency graph ingestion (`ingest`).
- Category-theoretic functor pipelines for both import map compaction/compression (`generate`) and quotient/tree-index bundling (`bundle`).
- Configurable resolvers (`Application`, `Local`, `Node`, `CDN`) managed via a central `Registry` and environment presets (`presets/node` and `presets/browser`).
- Distinct directory options separating the target package working directory (`cwd`), the entry point source directory (`source`), and the resolver workspace boundary (`root`).

## Installation

You can install Atlas using your favorite package manager. To install with `pnpm`, run:

```bash
pnpm install @dashkite/atlas
```

## Usage

### Generating an Import Map

```coffeescript
import { generate } from "@dashkite/atlas"
import browserResolvers from "@dashkite/atlas/presets/browser"

do ->
  map = await generate "index.js",
    cwd: "/path/to/app"
    source: "build/browser/src"
    resolvers: browserResolvers
  console.log JSON.stringify map, null, 2
```

### Creating an Application Bundle (ZIP)

```coffeescript
import { bundle, Resolvers } from "@dashkite/atlas"

Resolvers.Registry.register "local@workspace",
  Resolvers.Local.make
    root: "/path/to/workspace"
    patterns: [ "**/.tempo/repos/**/*", "packages/**/*" ]

do ->
  zipBuffer = await bundle "gateway.js",
    cwd: "/path/to/workspace/.tempo/repos/app"
    source: "build/node/src/shell"
    resolvers: [ "application", "local@workspace", "node" ]
```

## Other Resources

- [Recipes](docs/recipes.md)
- [Reference](docs/reference.md)
- [Technical Notes](docs/technical-notes.md)
- [Implementation Guide](docs/guides/implementation.md)
- [Testing](docs/testing.md)
