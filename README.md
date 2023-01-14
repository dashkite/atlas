# Atlas

*Manage JavaScript modules in JavaScript.*

```coffeescript
import { Reference, jsdelivr } from "@dashkite/atlas"

reference = Reference.create "@dashkite/quark", "latest"

# generate an import map using jsdelivr as the backing store...
console.log reference.map.toJSON jsdelivr
```

## Install

You know the drill.

```
npm i @dashkite/atlas
```

## Usage

### ATLAS_CONDITIONS

Set the `ATLAS_CONDITIONS` environment variable to set the import conditions that Atlas uses to determine the path for an import map.

## Status

Atlas is experimental and under active development. You probably not use it in production.

## Resources

- [API Reference](./docs/api-reference.md)
- [Design Guide](./docs/design-guide.md)

