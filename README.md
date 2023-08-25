# Atlas

*Manage JavaScript modules in JavaScript.*

```coffeescript
import * as Atlas from "@dashkite/atlas"

do ->
  # generate an import map
  console.log await Atlas.generate [ "build/index.js" ]

```

## Install

You know the drill. Using your favorite package manager, install `@dashkite/atlas`. For example, to install with `pnpm`, run:

```
pnpm add -D @dashkite/atlas
```

## Status

Atlas is experimental and under active development. You probably should not use it in production. You may want to check out [JSPM](https://jspm.org/).

## Limitations

The import map that Atlas generates is unlikely to work for your development process and cannot currently be customized. Making Atlas configuable is on [our roadmap](https://github.com/dashkite/atlas/issues).

