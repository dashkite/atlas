# Atlas

*Generate JavaScript import maps for a given set of entry points.*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Atlas is a robust library that analyzes module dependencies and generates compacted, optimized JavaScript import maps. It provides an extensible system of generators for mapping various types of dependencies to their appropriate URLs.

## Features

- Dependency analysis using `esbuild` to accurately determine the module graph.
- Generates mappings for CDN dependencies, relative dependencies, and Sky module conventions.
- Top-Down Verified Compaction algorithm to minimize import map size without causing shadowing conflicts.
- Extensible generator architecture allows creators to register custom mapping strategies.
- Supports scoped mappings to handle overlapping dependency versions gracefully.

## Installation

You can install Atlas using your favorite package manager. To install with `pnpm`, run:

```bash
pnpm install @dashkite/atlas
```

## Usage

Here is a common scenario for generating an import map and printing it to the console using the Sky preset:

```coffeescript
import Atlas from "@dashkite/atlas"
import SkyPreset from "@dashkite/atlas/presets/sky"

SkyPreset.apply
  provider: "jsdelivr"
  origin: "https://modules.acme.org"
  build: "/build/browser/src"

do ->
  # generate an import map from an entry point
  map = await Atlas.generate [ "build/index.js" ]
  console.log JSON.stringify map, null, 2
```

## Other Resources

- [Recipes](docs/recipes.md)
- [Reference](docs/reference.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing](docs/testing.md)
