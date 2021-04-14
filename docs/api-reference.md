# API Reference

_Atlas_

## Types

### Reference

#### Class Generics

##### equal

*equal a, b → boolean*

Given two Reference instances, returns true if they’re semantically equal and false otherwise. Equality defaults to strict equalty but may be overridden by subtypes.

#### Class Methods

##### create

*create name, description → reference*

#### Instance Methods

##### glob

##### capture

##### toString

#### Instance Properties

| Property     | Type                         | Getter | Setter | Description                                                  |
| ------------ | ---------------------------- | :----: | :----: | ------------------------------------------------------------ |
| name         | string                       |   ✓    |        | The name of the referenced module.                           |
| description  | string                       |   ✓    |        | A description, such as the semver range or URL.              |
| version      | string                       |   ✓    |        | The version to which the module description resolves.        |
| files        | array of paths               |   ✓    |        | A list of files included in the module.                      |
| dependencies | set of references            |   ✓    |        | A list of a module’s dependencies.                           |
| scopes       | set of set of references     |   ✓    |        | Scopes for a given module’s dependency tree.                 |
| exports      | dictionary of relative paths |   ✓    |        | A module’s exports, with wildcards and conditions resolved.  |
| aliases      | dictionary of aliases        |   ✓    |        | A module’s aliases (internal imports) with wildcards and conditions resolved. |

### RegistryReference

*extends Reference*