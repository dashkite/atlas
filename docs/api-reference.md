# API Reference

_Atlas_

## Types

### Reference

#### Generics

##### equal

*equal a, b → boolean*

Given two Reference instances, returns true if they’re semantically equal and false otherwise. Equality defaults to strict equalty and is overridden by subtypes.

#### Class Methods

##### create

*create name, description → reference*

Given a name and a description, such as a semver range or URL, returns a `Reference` instance. Uses the description to determine how to create the reference. Will return the same object given the same name and description. 

#### Instance Methods

##### glob

*glob pattern → array of paths*

Applies the given globbing pattern against the `files` property, returning the list of files that matched.

##### capture

*capture pattern → array of paths*

Applies the given globbing pattern against the `files` property, returning the list of the matched portion of the paths for the files that matched.

##### toString

Returns a string description of the module.

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
| map          | `ImportMap` instance         |   ✓    |        | A object encapsulating a module’s import map.                |

### RegistryReference

*extends Reference*

### FileReference

*extends Reference*

### Scope

#### Class Methods

##### create

#### Instance Methods

##### has

##### add

##### delete

##### canAdd

#### Instance Properties

| Property     | Type   | Getter | Setter | Description                        |
| ------------ | ------ | :----: | :----: | ---------------------------------- |
| name         | string |   ✓    |        | The name of the referenced module. |
| dependencies |        |        |        |                                    |
| size         |        |        |        |                                    |



### ImportMap

#### Class Methods

##### create

#### Instance Methods

##### toJSON

*toJSON generator → json*



## Generics

### jsdelivr

*jsdelivr scope → url*

*jsdelivr reference → url*

*jsdelivr file-reference → path*


