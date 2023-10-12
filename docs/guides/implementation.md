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
- `Relative`: generates mappings for dependencies whose source path lay within a given build directory relative to the HTML resource containing the import map.
- `Sky`: generates mappings for linked dependencies, using the file hash and Sky environment to generate the URL. The Sky generator will be moved into a separate module.

The generators to most of the heavy lifting of transforming a dependency to a mapping, the essence of which is generating file mappings and import specifiers into URLs.

### Dependencies

Dependencies consist of three properties:

- `source`: an object describing the source file
- `module`: an object describing the module containing the source file
- `import`: an object describing the how file was imported

#### Source

The source object contains one property, the `path`.

#### Module

The module object consists of a `specifier`, `name`, `version`, and `path`. It may also include a optional `scope`. The `specifier` is the name, prefixed by the scope if it exists. The `path` is the path to the module (the directory containing its `package.json` file).

#### Import

The import object consists of the import `specifier` and a `scope`. The import scope has `source` and `module` properties, just a dependency. Thus, the import scope is itself a dependency description, except without an `import` property. Future versions may simply reference the corresponding dependency directly.

## The Generators

Generators are registered with Atlas using the `Generator.register` function. The argument must be a generator object, with `matches`, `apply`, and `scope` functions, or an array of such objects.

Generators are matched in LIFO order, meaning the last one registered has the highest precedence. There is also a default generator that generates a trivial mapping.

Generators provide a constructor function, `make` that accepts a configuration object. The typically pattern for registering generators thus looks something like:

```coffeescript
    Generators.register [
      CDN.make { provider }
      Relative.make { build }
      Sky.make { origin }
    ]
```

However, in practice, you would likely package up common combinations of generators into presets.

### CDN

The CDN generators constructor function takes the name of the CDN provider. There is only one such provider at this time, `jsdelivr`. However, implementing other providers would be similar.

```coffeescript
  make: ({ provider }) -> CDNs[ provider ]
```

The predicate is relatively simple: we check to see if the source file is published (contained within a `node_modules` folder), implying that it’s a production dependency. We’re assuming here that development dependencies are linked.

```coffeescript
    matches: ( dependency ) ->
    	Source.isPublished dependency
```

Applying the generator is bit trickier. We define helper functions here to keep things clean:

```off
    apply: ( dependency ) ->
      scope: await Generators.scope dependency.import.scope
      specifier: getSpecifier dependency
      target: getURL dependency
```

We use `Generators.scope` to generate the scope because we can import a production dependency from anywhere. 

The `getSpecifier` function checks to see if the import specifier is a relative path, in which case we need to construct the specifier URL from the scope. Otherwise, we know this is just the bare import specifier, which we can use directly:

```coffeescript
getSpecifier = ( dependency ) ->
  if Specifier.isRelative dependency
    XRL.join [
      XRL.pop getURL dependency.import.scope
      dependency.import.specifier
    ]      
  else 
    dependency.import.specifier
```

(The XRL helpers are URL extensions for manipulating URLs.)

The `getURL` function, which is used by `getSpecifier` and for the generator’s `scope` function constructs a URL from the relative path of the source file and the module’s URL:

```coffeescript
getURL = ({ source, module }) ->
  do ({ path } = {}) ->
    path = Source.relative { source, module }
    do ({ specifier, version } = module ) ->
      XRL.join [
        "https://cdn.jsdelivr.net/npm"
        "#{ specifier }@#{ version }"
        path
      ]
```

The `getURL` function is the part that would change between providers, although it’s possible the only difference would be the URL template itself. In fact, we could use Polaris or a lightweight template function, such as the one defined in Masonry Targets (which itself needs to be incorporated into Joy).

### Relative

The Relative generator constructor function takes the directory that it’s responsible for (you could have two such directories by registering two instances of Relative generators, bound to different directories):

```coffeescript
Relative.make build: "build/browser/src"
```

The predicate is thus quite simple:

```coffeescript
    matches: ( dependency ) ->
      Directory.within build, dependency.source.path
```

(The `build` variable is in the closure of the object returned by `make`.)

The generator function is a bit more complex. 

- We assume the scope is also relative, since it would be strange for an external module to import something from within the app.
- For the specifier, we first check to see if it’s an alias. If so, we use that.
- Otherwise, we construct a URL from the scope. For the target, we use the `getURL` helper.

```coffeescript
    apply: ( dependency ) ->

      do ({ scope, specifier, target } = {}) ->

        scope = XRL.Path.root do ->
          Path.relative build, 
            dependency.import.scope.source.path

        specifier = do ->

          if Specifier.isAlias dependency
            dependency.import.specifier
          else
            XRL.Path.join [ 
              XRL.pop scope
              dependency.import.specifier
            ]

        target = getURL dependency

        { scope, specifier, target }
```

The `getURL` function simply constructs a URL from the import specifier and the relative source path:

```coffeescript
    getURL = ( dependency ) ->
      XRL.Path.root Path.relative build, 
        dependency.source.path
```

### Sky

The Sky generator constructor function takes an origin:

```coffeescript
Sky.make origin: "https://modules.dashkite.com"
```

Specifying the origin allows us to generate it at build time based on the Sky environment. For example, here’s how we set it in the Genie Import Maps preset:

```coffeescript
      SkyPreset.apply
        provider: "jsdelivr"
        build: "build/browser/src"
        origin: await DRN.resolve "drn:origin/modules/dashkite/com"
```

The predicate simply checks to make sure the module is both external and not published (installed in `node_modules`):

```
    matches: ( dependency ) -> 
      ( Source.isExternal dependency ) &&
        !( Source.isPublished dependency )
```

which is typical of a linked dependency.

The generator function:

- Checks to see if the import specifier is relative. 
- If so, we can assume that the import scope is also a Sky dependency. 
- We obtain the scope using the `getURL` helper and specifier by joining the scope URL to the specifier.
- If the specifier is not relative, it must be a module specifier. 
- In that case, we can’t be sure of the import scope, so we use the `Generator.scope` function to obtain the scope. We can use the specifier directly, since it’s a module specifier.
- Finally, we use the `getURL` helper to get the target URL.

**Important:** The resulting specifier will consequently be based on the scope, not the dependency itself. That’s because we’re emulating how the browser generates the URL specifier. For URLs containing content hashes, the resulting URL will be “wrong” because it will be using the hash associated with the import scope. We’re mapping that URL to the correct URL. Unfortunately, we can’t simply use the specifier, because it will be resolved using the base URL of the document, *not* the import scope.

```coffeescript
    apply: ( dependency ) ->

      do ({ scope, specifier, target } = {}) ->

        if Specifier.isRelative dependency

          scope = await _getURL dependency.import.scope 

          specifier = XRL.join [
            XRL.pop scope
            dependency.import.specifier
          ]

        else

          scope = await Generators.scope dependency.import.scope

          specifier = dependency.import.specifier

        target = await _getURL dependency

        { scope, specifier, target }
```

The `getURL` function (the underscore variant, `_getURL` just wraps `getURL`, passing in the `origin` configuration option) obtains the dependency’s hash, module URL, and relative path, and composes them, along with the origin, into a URL:

```coffeescript
getURL = ({ origin, dependency }) ->
  do ({ hash, base, path } = {}) ->
    hash = await getHash dependency
    base = getModuleURL { origin, dependency }
    path = Source.relative dependency
    XRL.join [ base, hash, path ]
```

The `getHash` function is the most interesting helper. We use Zephyr to read the hashes generated by the Sky publish Genie task. Zephyr automatically parses them for us and returns an object. We lookup the hash corresponding to the relative source path and return it, throwing if it’s not there:

```coffeescript
getHashes = ({ module }) ->
  Zephyr.read Path.join module.path, ".sky", "hashes.yaml"

getHash = ({ module, source }) ->
  do ({ path, hashes } = {}) ->    
    if ( hashes = await getHashes { module } )?
      path = Source.relative { source, module }
      hashes[ path ] ?
        throw new Error "No hash for [ #{ path } ]"
    else
      throw new Error "No hashes found for module at 
        [ #{ module.path } ]"
```

## Presets

Different generators can be packaged up into presets to make it easier to use Atlas in a variety of scenarios. Presently, there’s only one preset, the Sky Preset. You can use it as shown above in the discussion of the Sky generator.

Presets register generators based on a given usage pattern, using the `Generator.register` interface. See the introduction to Generators above for an example. Presets should provide an `apply` function that accepts any configuration and registers the generators.

## Appendix: Import Maps

Import maps are extensively documented:

- On [MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script/type/importmap)
- By the [W3C Working Group](https://github.com/WICG/import-maps#readme)
- In [the specification](https://html.spec.whatwg.org/multipage/webappapis.html#import-map)

However, there are a few things that may not be not immediately obvious:

- The keys in a *module specifier map* (what we refer to as specifiers in Atlas) must be either bare module specifiers, URLs, or paths. Bare module specifiers are basically specifiers that aren’t URLs or paths.
- Bare module specifiers, like `@dashkite/joy`, are mapped without transformation. However, paths are assumed to be relative URLs, where the document URL is the base. This is true even within scopes.
- In other words, paths in scoped mappings are not resolved using the scope, but the document URL.
- Similarly, aliases are treated as bare module specifiers.

## Appendix: Roadmap

Atlas works well for our present purposes, but to make it more generally useful, we would like need to make some improvements:

- Provide API reference documentation
- Provide an implementer’s guide for generators and presets
- Move the Sky generator and preset into a separate module
- Add a Local generator for developing against a local server
- Expand the README documentation
- Add tests (we currently test by using the generated import maps in our apps)
- Handle aliases in all the generators (or remove support for them in the Sky generator)
- Support dynamic configuration, ex: `“sky", { origin }`
- Dynamically import preset modules based on configuration
- Support use of configuration files that are automatically imported
- Add CLI support and plug-ins for popular task runners