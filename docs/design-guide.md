# Design Guide

*Atlas*

Atlas defines three main types:

- `Reference`, a module reference, characterized by a name and description (a URL or version range)
- `Scope`, the scope in which a module was or will be imported
- `ImportMap`, allowing the generation of an [import map][] for given module

[import map]: https://github.com/WICG/import-maps/blob/main/README.md

## Reference

There are two main `Reference` subtypes:

- `RegistryReference`, a reference to a module in the NPM registry
- `FileReference`, a reference to module available from the local filesystem

Eventually `Reference` will be extended to support GitHub and general Web references.

The `Reference` interface allows for the inspection of a module and for comparisons with other modules. Thus, all References have properties such a `dependencies` and `files` and `Reference` defines functions like `similar` and `choose`.

## Scope

The `Scope` type encapsulates the logic for detecting conflicts and placement of modules within a scope.