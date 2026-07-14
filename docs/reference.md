# Reference

## Map

### make

$make: \to map$

Creates a new, empty import map structure containing `imports` and `scopes`.

### from

$from: [map] \to map$

Creates an import map object structure directly from an existing map representation.

### add

$add: [map, dependency] \dashrightarrow map$

Adds a given dependency to the import map. The function uses the registered generators to transform the dependency into a mapping, determines the correct scope, and stores the specifier-to-target assignment within the map.

```coffeescript
map = Map.make()
await Map.add map, dependency
```

### optimize

$optimize: [map] \to map$

Optimizes an import map by performing Top-Down Verified Compaction. It attempts to lift mappings to the broadest possible scope (root `imports` or top-level parent directories) while guaranteeing that no accidental shadowing occurs.

## Generators

### register

$register: [generator\_or\_array] \to \emptyset$

Registers one or more generator objects with the system. Generators are added to a last-in, first-out queue, meaning the most recently registered generator takes precedence during matching.

```coffeescript
Generators.register [
  CDN.make provider: "jsdelivr"
]
```

### initialize

$initialize: \to \emptyset$

Initializes all registered generators by calling their `initialize` method if present.

## analyze

$analyze: [entries] \dashrightarrow generator$

Analyzes the module dependencies for the given entry points using `esbuild`. It returns an asynchronous generator (reactor) that yields dependency objects representing source files, modules, and their import paths.
