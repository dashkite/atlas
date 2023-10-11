# Implementation Guide

*for DashKite Atlas*

## The Algorithm

The high-level algorithm is expressed in the `generate` function itself:

```coffeescript
generate = ( entries, map ) ->
  map = if map? then Map.from map else Map.make()
  Map.add map, analyze entries
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
      scope = if scope?
        findMinimalScope { map, scope, specifier, target }
      else
        map.imports
      scope[ specifier ] = target
    map
```

We first check to see if the specifier and target are the same, which means we don’t need to add it. Next, we compute the scope by finding the minimal scope that doesn’t introduce a conflict. A conflict occurs when the same specifier is already mapped to a different target within the same scope. Once we have the minimal scope, we add the mapping.

But how did we get the mapping?

### Generators

Different kinds of dependencies require different kinds of mappings. For example, we need different mappings for external dependencies than for those within an application. The functions that produce these mappings are called *generators*. We wrap these functions in generator objects that also provide a predicate that tells us whether a given generator can produce a mapping for a given dependency. (They also include a function to generate a scope URL.)

Producing a mapping is thus a matter of finding a generator that can produce it. The `Genarator.find` function implements this, using `Generator.match` as the predicate for `Array.find`.

```coffeescript
Generators =

  # ...

  match: ( dependency ) ->
    ( generator ) -> generator.matches dependency

  find: ( dependency ) ->
    generators.find Generators.match dependency
```

Generators are registered using the `Generator.register` interface, which is the basis for Atlas’ extensibility. There are three built-in generators:

We currently have three mapping generators:

- `CDN`: generates mappings for `node_modules` dependencies to their corresponding CDN URL. Right now, we only support the JSDelivr CDN, but it’s easy to add new ones.
- `Relative`: generates mappings for dependencies in the same source tree as an entry point to URLs relative to the HTML resource containing the import map.
- `Sky`: generates mappings for linked dependencies, using the file hash and Sky environment to generate the URL. The Sky generator will be moved into a separate module.

The generators to most of the heavy lifting of transforming a dependency to a mapping, the essence of which is generating file mappings and import specifiers into URLs.

### Dependencies

Dependencies consist of three properties:

- `source`: an object describing the source file
- `module`: an object describing the module containing the source file
- `import`: an object describing the how file was imported

## The Generators

## CDN

The CDN generators constructor function (`make`) takes the name of the CDN provider. There is only one such provider at this time, `jsdelivr`. However, implementing other providers would be similar.

The predicate is relatively simple: we check to see if the source file is contained within a `node_modules` folder, which implies that it’s a production dependency. We’re assuming here that development dependencies are linked.

```coffeescript
    matches: ( dependency ) ->
      Directory.contains "node_modules",
        dependency.source.path
```

Applying the generator is bit trickier. We define helper functions here to keep things clean:

```off
    apply: ( dependency ) ->
      scope: await Generators.scope dependency.import.scope
      specifier: getSpecifier dependency
      target: getURL dependency
```

We use `Generators.scope` to generate the scope because we can import a production dependency from anywhere. 

The `getSpecifier` function