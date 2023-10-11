# Atlas

*Generate JavaScript import maps for a given set of entry points.*

```coffeescript
import Atlas from "@dashkite/atlas"
import SkyPreset from "@dashkite/atlas/presets/sky"

SkyPreset.apply
  origin: "https://modules.acme.org"
  build: "/build/browser/src"

do ->
  # print an import map to the console
  console.log await Atlas.generate [ "build/index.js" ]
```

## Install

You know the drill. Using your favorite package manager, install `@dashkite/atlas`. For example, to install with `pnpm`, run:

```
pnpm add -D @dashkite/atlas
```

## Customization

By default, Atlas just blindly maps import specifiers to source paths. You must register the generators you want to use by using the `register` function:

```coffeescript
import Atlas from "@dashkite/atlas"
import CDN from "@dashkite/atlas/generators/cdn"
import Relative from "@dashkite/atlas/generators/relative"

Atlas.register CDN.make provider: "jsdeliver"
Atlas.register Relative.make build: "build/browser/src"
```

You may also pass an array to `register` to register multiple presets at once:

```coffeescript
Atlas.register [
  CDN.make provider: "jsdeliver"
  Realtive.make build: "build/browser/src"
]
```

The order in which they are evaluated is last-first.

There are presently three generators available:

- `CDN`: generates mappings for dependencies installed into `node_modules` for a given CDN. Presently, only the JSDelivr CDN is supported.
- `Relative`: generates mappings for dependencies within a given directory. You must provide the directory.
- `Sky`: generators mappings for dependencies outside the current directory and not installed into `node_modules`, using the Sky module loading convention for a given domain.

### Presets

You can also use presets, as in the example above. Presently, the only preset is the Sky preset.

### Custom Generators

Finally, you may define your own generators and presets. Documentation for defining a generator is forthcoming.

## Status

Atlas is under active development. You should not use it in production. You may want to check out [JSPM](https://jspm.org/) instead.

