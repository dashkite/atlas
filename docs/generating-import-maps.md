# Generating Import Maps

*Implementation Guide, Atlas*

Atlas relies on three central abstractions:

- A reference to a module
- A scope, representing the context in which a module was imported
- An import map, which encapsulates the logic for generating an import map

A module reference provides a rich interface with which to inspect a given module. For example, we can see the dependencies of a module or the files it includes. While useful by itself, this also simplifies the logic for generating an import map.

There are three properties exposed by this interface that are of particular interest when generating import maps:

- `scopes` which is effectively a flattened dependency tree in the form of a set (the reason we call it `scopes` instead of `flattenedDependencyTree` or something along those lines will hopefully become clear in what follows)
- `exports`, which are the module’s own exports, with wildcards and conditions resolved, but with relative paths (which can be converted into their final form when we generate the import map)
- `aliases`, which is just what we call the [internal imports][] to avoid overloading the word *import*, with wildcards and conditions resolved, as with `exports`, and using relative paths

These together provide the building blocks for generating an import map.

We first *optimize* the scopes, which again, is just the flattened dependency tree. The basic idea here is to attempt to place each dependency in its appropriate scope. This can be the root scope or module scope. Within module scope, we have both a name scope and a name-version scope, depending on how precise we need to be. This allows us to leverage the design of import maps, which allow us to import the appropriate resource for a given context.

For example, suppose modules A and B both depend on different versions of C. We can scope them so that we get the expected version for each module. Suppose further that the two different versions of C depend on different versions of D. We can use the most specific module scope to make sure each gets the version it expects as well.

The placement algorithm is quite simple:

1. Attempt to place the reference in the root scope. Provided there’s no conflicting version already there, we’re good to go.
2. If there was a conflict, try the module-name scope, and then the module-name-version scope. This last one is guaranteed to work, since a module can only import another module once.

Once we’ve optimized the scopes, we’re ready to produce the import map. For each module reference within each scope, we just need to merge its exports with the other module references in the same scope. We also need to place any aliases it defines into the module-name-version scope _for that module_ (not for the importing module, since it doesn’t need its dependencies aliases).

In order to do this, we need to convert the relative paths provided by the `exports` and `aliases` properties into URLs: relative URLs for file references and absolute for registry references. For this, we provide a generator function, whose job is to take a given scope or reference and turn it into a URL. That’s why the `toJSON` method of `ImportMap` takes a generator.

In reality, generating the final map consists of three parts:

- Load the immediate dependencies into the `imports` property. We’re assuming here that the target module is whatever is running in the browser, so it’s immediate dependencies need to be accounted for.
- Map the optimized scopes into the import map object, using URLs for the keys for any scopes (besides the root scope).
- Add in the aliases, if any, into the corresponding name-version module scopes.

[internal imports]: https://nodejs.org/api/packages.html#packages_subpath_imports