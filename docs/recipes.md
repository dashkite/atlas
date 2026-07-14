# Usage Guides

## Generating a basic import map

This task involves generating an import map for a local build.
Atlas enables this by analyzing the specified entry points to find dependencies, matching them against registered generators, and optimizing the resulting map.

```coffeescript
import Atlas from "@dashkite/atlas"
import Relative from "@dashkite/atlas/generators/relative"

# external initialization of generators
Atlas.register Relative.make build: "build/browser/src"

map = await Atlas.generate [ "build/index.js" ]
```

1. We import Atlas and the `Relative` generator.
2. We register the generator by passing the build directory to its `make` function.
3. We call `Atlas.generate` with the entry points we want to analyze. The algorithm will automatically discover dependencies, translate them using the `Relative` generator, and compact the map.

## Registering multiple generators

This task involves mapping different kinds of dependencies, such as local application files and external CDN packages.
Atlas enables this by allowing creators to register multiple generators in an array. Atlas will try each generator in last-in, first-out order to match dependencies.

```coffeescript
import Atlas from "@dashkite/atlas"
import CDN from "@dashkite/atlas/generators/cdn"
import Relative from "@dashkite/atlas/generators/relative"

# external configuration setup
Atlas.register [
  CDN.make provider: "jsdelivr"
  Relative.make build: "build/browser/src"
]

map = await Atlas.generate [ "build/index.js" ]
```

1. We supply an array of generators to `Atlas.register`.
2. When `generate` analyzes a dependency, it queries the generators in reverse order.
3. A local file will match the `Relative` generator and resolve to a local path.
4. An external package from `node_modules` will match the `CDN` generator and resolve to a JSDelivr URL.

## Building an import map incrementally

This task involves constructing an import map by adding dependencies manually, which is useful when integrating with a larger build pipeline or transforming maps over time.
Atlas enables this by exposing the underlying `Map` operations, allowing creators to decouple analysis from the mapping and optimization phases.

```coffeescript
import { Map } from "@dashkite/atlas/src/helpers/import-map"
import analyze from "@dashkite/atlas/src/helpers/analyze"
import Relative from "@dashkite/atlas/src/generators/relative"
import Atlas from "@dashkite/atlas"

# register a generator
Atlas.register Relative.make build: "build/browser/src"

# start with a clean map
map = Map.make()

# generate an asynchronous iterator of dependencies
dependencies = analyze [ "build/index.js" ]

# add each dependency incrementally
for await dependency from dependencies
  # add will internally apply the registered generators
  map = await Map.add map, dependency

# optimize to perform top-down verified compaction
optimizedMap = Map.optimize map
```

1. We create an empty map structure with `Map.make`.
2. We analyze the entry point using the `analyze` function to obtain an asynchronous iterator (a reactor) of `dependency` objects.
3. We loop over the reactor and incrementally `Map.add` each dependency. Atlas translates the dependency to a scope and target using our registered `Relative` generator.
4. Finally, we call `Map.optimize` to compact the map and remove overlapping scopes.

## Merging into an existing import map

This task involves adding new dependencies to an import map that has already been generated or defined externally.
Atlas enables this by allowing creators to initialize a map structure from an existing plain object using `Map.from`.

```coffeescript
import { Map } from "@dashkite/atlas/src/helpers/import-map"
import analyze from "@dashkite/atlas/src/helpers/analyze"

existing =
  imports:
    "@dashkite/joy": "https://cdn.jsdelivr.net/npm/@dashkite/joy@1.0.0/index.js"
  scopes: {}

# inflate the object into an Atlas map structure
map = Map.from existing

# add new dependencies directly as a reactor
map = await Map.add map, analyze [ "build/client.js" ]

# optimize the combined result
finalMap = Map.optimize map
```

1. We start with an existing import map containing pre-defined `imports` or `scopes`.
2. We load it into Atlas using `Map.from`.
3. We use `Map.add` to add the results of a new `analyze` pass. The `Map.add` function can gracefully accept a reactor (the result of `analyze`) directly, resolving all items automatically.
4. We finalize the map by running `Map.optimize` to incorporate the new scopes optimally alongside the existing imports.
