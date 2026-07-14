# Technical Notes

### Import Maps

Import maps are a native browser technology that allows developers to control how JavaScript modules resolve import specifiers. They are fundamentally important because they eliminate the need for complex build-time bundlers when resolving bare module specifiers (e.g., `import _ from "lodash"`). Instead of running a bundler to rewrite these specifiers to static URLs, an import map instructs the browser exactly where to fetch the requested module.

This capability effectively transforms import maps into a universal package management service directly inside the browser. By centralizing the resolution logic, multiple independently deployed applications or micro-frontends can share common dependencies dynamically, leading to smaller payloads and simplified workflows without losing the convenience of standard Node.js-style module resolution.

For more detailed reading on import maps as a technology, consult the following resources:
- [MDN: Import map JSON representation](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/script/type/importmap#import_map_json_representation)
- [HTML Specification: Import maps](https://html.spec.whatwg.org/multipage/webappapis.html#import-map)
- [Web.dev: Import maps in all modern browsers](https://web.dev/blog/import-maps-in-all-modern-browsers)

### The Algorithm

The high-level algorithm is expressed in the `generate` function itself:

```coffeescript
generate = ( entries, map ) ->
  map = if map? then Map.from map else Map.make()
  Map.optimize await Map.add map, analyze entries
```

There are two high-level interfaces here:

- `analyze`: performs a dependency analysis on the given entry points and returns a reactor producing dependency objects, which include module and import information.
- `Map.add`: adds a list of dependencies—in the form of a reactor—to a map. `add` is a generic, so this is just a wrapper around a function that adds a single dependency.

### Mappings

Adding a dependency to a map involves transforming a dependency into a mapping, which, in turn, consists of three properties:

- `scope`: a URL specifier for the import scope for the dependency
- `specifier`: a module specifier or a URL corresponding to the dependency itself
- `target`: the URL corresponding to the specifier

Effectively, the scope and specifier are the URLs that the browser would compute for a given dependency. Thus, if the specifier and target are the same, we can ignore the mapping, since that would mean that the browser can compute the target without the mapping.

Given a mapping, adding it to the map looks like this:

```coffeescript
    generic add, Type.isObject, isMapping,
      ( map, { scope, specifier, target }) ->
        unless specifier == target
          _scope = if scope?
            if scope.startsWith "/"
              map.imports
            else
              map.scopes[ XRL.directory XRL.pop scope ] ?= {}
          else
            map.imports
          _scope[ specifier ] = target
        map
```

We first check to see if the specifier and target are the same, which means we don't need to add it. Next, we determine the scope. If the scope is provided, we use it (ensuring it's treated as a directory-level scope); otherwise, we default to the global `imports`.

### Generators

Different kinds of dependencies require different kinds of mappings. For example, we need different mappings for external dependencies than for those within an application. The functions that produce these mappings are called generators. We wrap these functions in generator objects that also provide a predicate that tells us whether a given generator can produce a mapping for a given dependency.

Producing a mapping is thus a matter of finding a generator that can produce it. The `Genarator.find` function implements this, using `Generator.match` as the predicate for `Array.find`.

Generators are registered using the `Generator.register` interface, which is the basis for Atlas' extensibility. There are three built-in generators:

- `CDN`: generates mappings for `node_modules` dependencies to their corresponding CDN URL.
- `Relative`: generates mappings for dependencies whose source path lay within a given build directory.
- `Sky`: generates mappings for linked dependencies, using the file hash and Sky environment.

### The Compaction Algorithm

Atlas uses a Top-Down Verified Compaction algorithm to minimize the size of the generated import map while ensuring behavioral correctness.

The process consists of three main phases:

1. Grouping and Prioritization: Mappings are grouped by their specifier and target, then sorted by frequency so that the most impactful optimizations are processed first.
2. Verified Optimization: For every mapping, Atlas attempts to find its most general "safe home"—starting with complete removal, then promotion to the root `imports`, and finally lifting through parent directories. Each move is verified against a resolver to ensure it perfectly preserves all original requirements.
3. Final Cleanup: After all optimizations are committed, any scopes that have become empty are removed from the map.

This strategy ensures that Atlas generates the smallest possible map that is guaranteed to be completely correct relative to the initial uncompacted results.

### The Shadowing Problem

The primary challenge in import map compaction is avoiding accidental shadowing. Because the browser resolves specifiers by finding the most specific matching scope and stopping there, lifting a mapping to a broader parent scope can "capture" modules that weren't intended to be affected.

To solve this, Atlas checks each possible conflict when promoting. By trying the broadest scopes first and only committing safe moves, we achieve maximal compaction without shadowing.
