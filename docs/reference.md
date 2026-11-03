# Reference

## Pipeline Functions

All pipeline functions operate relative to a target package working directory (`options.cwd`) and accept an optional entry-point base directory (`options.source`).

### generate

$generate: [entries, options] \dashrightarrow importMap$

Generates an optimized WHATWG JavaScript import map object (`{ imports, scopes }`) from one or more entry points.

- **`entries`** *(String | Array\<String\>)*: One or more entry point file paths, resolved relative to `options.source` (unless already absolute).
- **`options`** *(Object, optional)*:
  - **`cwd`** *(String, default: `process.cwd()`)*: The target package root directory (where `package.json` and `node_modules` reside). Passed to `esbuild` as `absWorkingDir` and used as the base directory for intra-application module paths.
  - **`source`** *(String, default: `options.cwd`)*: Base directory used to resolve input `entries` (`Path.resolve(cwd, options.source ? ".")`). Entry points are resolved via `Path.resolve(source, entry)` while all module graph paths remain relative to `cwd`.
  - **`resolvers`** *(Array\<String\>, default: `presets/node`)*: Ordered array of registered resolver keys to query during ingestion and URL resolution.
  - **`external`** *(Array\<String\>, default: `[]`)*: Additional module specifiers to mark as external during `esbuild` analysis (`@aws-sdk/*` and `esbuild` are always externalized).

```coffeescript
import { generate } from "@dashkite/atlas"
import browserPreset from "@dashkite/atlas/presets/browser"

map = await generate "index.js",
  cwd: "/path/to/package"
  source: "build/browser/src"
  resolvers: browserPreset
```

### bundle

$bundle: [entries, options] \dashrightarrow Buffer$

Analyzes, ingests, and compiles the dependency graph for the given entry points into a compressed ZIP archive (`Buffer`) suitable for Node.js or AWS Lambda execution.

- **`entries`** *(String | Array\<String\>)*: One or more entry point file paths, resolved relative to `options.source` (unless already absolute).
- **`options`** *(Object, optional)*:
  - **`cwd`** *(String, default: `process.cwd()`)*: The target package root directory. Used as `esbuild`'s `absWorkingDir`, to locate the root `package.json` placed at the root of the ZIP archive, and to compute each entry point's archive-relative path (`Path.relative(cwd, Path.resolve(source, entry))`).
  - **`source`** *(String, default: `options.cwd`)*: Base directory used to resolve input `entries` (`Path.resolve(cwd, options.source ? ".")`). While entries are located using `source`, their destination paths inside the ZIP archive remain relative to `cwd` so that package subpath imports (`#...`), relative imports (`../...`), and AWS Lambda handler paths remain consistent with the package root.
  - **`resolvers`** *(Array\<String\>, default: `presets/node`)*: Ordered array of registered resolver keys.
  - **`compact`** *(Boolean, default: `true`)*: Controls topological compaction in the compiler functor (`functors/compiler`).
  - **`external`** *(Array\<String\>, default: `[]`)*: Additional module specifiers to mark as external during `esbuild` analysis.

```coffeescript
import { bundle } from "@dashkite/atlas"

zipBuffer = await bundle "storage.js",
  cwd: "/path/to/package"
  source: "build/node/src/shell"
```

---

## Resolvers

Resolvers translate between dependency descriptors, canonical `atlas://` URLs, and target runtime URLs (`file://` or `https://`). Unlike pipeline functions (which take `cwd` and `source`), filesystem-backed resolvers accept **`root`** in their `.make(config)` factory configuration.

### Resolver Protocol

Custom and built-in resolvers implement the following four-method protocol:

- $resolver.match: [context] \to boolean$ — Returns `true` if the resolver claims the dependency described by `context` (`{ source, cwd }`), or `false` otherwise.
- $resolver.encode: [descriptor] \to url$ — Encodes a dependency descriptor (`{ resolver, module, path }` or `{ resolver, path }`) into a canonical `atlas://` URL string.
- $resolver.decode: [url] \to descriptor$ — Inverse of `encode`; decodes a canonical `atlas://` URL string into a dependency descriptor (`{ resolver, module: { scope, name, version }, path }` or `{ resolver, path }`).
- $resolver.resolve: [url] \to targetUrl$ — Resolves a canonical `atlas://` URL string into a target runtime URL (`file://...` or `https://...`).

Because custom resolvers are external implementations, the composite `MetaResolver` created by `Registry.make(keys)` acts as a contract-enforcing proxy around registered resolvers, validating configured resolver keys and the values returned by `match`, `encode`, `decode`, and `resolve`.

### Registry

- $Registry.register: [key, resolver] \to resolver$ — Registers a configured or custom resolver instance under `key` (e.g., `"local@workspace"` or `"cdn@jsdelivr"`).
- $Registry.get: [key] \to resolver$ — Retrieves a registered resolver instance by `key`.
- $Registry.make: [keys] \to metaResolver$ — Creates a composite `MetaResolver` proxy dispatching across the ordered array of `keys` and enforcing the resolver protocol contract.

### Application

$Application.make: [config] \to resolver$

Matches intra-application files (paths that do not contain `node_modules` and do not escape `cwd` via `..`). Encodes to `atlas://application/<path>`.

- **`config.root`** *(String, default: `process.cwd()`)*: Base directory used by `resolve(url)` to map `atlas://application/<path>` to `file://<root>/<path>`.

### Local

$Local.make: [config] \to resolver$

Matches local workspace or metarepo packages outside the application directory that match configured glob patterns (excluding `node_modules`). Encodes to `atlas://local[@key]/[<scope>/]<name>@<version>/<path>`.

- **`config.root`** *(String, **required**)*: Absolute path of the workspace or metarepo root directory used by `resolve(url)` (and as fallback base directory in `match(context)` when `context.cwd` is omitted).
- **`config.patterns`** *(Array\<String\>, default: `[ "../**/*", "packages/**/*" ]`)*: Glob patterns evaluated by `match(context)` against the dependency path (`context.source`) relative to `context.cwd ? @root`.

### Node

$Node.make: [config] \to resolver$

Matches dependencies residing within `node_modules`. Encodes to `atlas://node/[<scope>/]<name>@<version>/<path>`.

- **`config.root`** *(String, default: `process.cwd()`)*: Base directory used by `resolve(url)` to map `atlas://node/...` to `file://<root>/node_modules/<pkg>/<path>`.

### CDN

$CDN.make: [config] \to resolver$

Matches dependencies residing within `node_modules` and resolves canonical `atlas://cdn[@key]/...` URLs to remote HTTP CDN URLs using URL Codex templates.

- **`config.template`** *(String | Function, **required**)*: URL template string or function `(descriptor) -> templateString` using placeholders `{scope}`, `{name}`, `{version}`, `{specifier}`, `{release}`, `{versioned}`, and `{path*}`.

---

## Presets

- **`@dashkite/atlas/presets`**: Exports `{ node, browser }`.
- **`@dashkite/atlas/presets/node`**: Registers default `application`, `local@default` (`root: process.cwd()`), and `node` resolvers, and exports `["application", "local@default", "node"]`.
- **`@dashkite/atlas/presets/browser`**: Registers default `application`, `local@default`, `cdn@unpkg`, `cdn@jsdelivr`, and `cdn@esm` resolvers, and exports `["application", "local@default", "cdn@unpkg"]`.

---

## AtlasURL

`AtlasURL` provides symmetrical encoding and decoding functions for canonical `atlas://` URLs:

- $AtlasURL.encode: [descriptor] \to url$ — Encodes a dependency descriptor (`{ resolver, module, path }` or `{ resolver, path }`) into a canonical `atlas://` URL string.
- $AtlasURL.decode: [url] \to descriptor$ — Decodes a canonical `atlas://` URL string into `{ resolver, module: { scope, name, version }, path }` for module-qualified resolvers (selecting the scoped URL Codex pathname template `"/{scope}/{versioned}/{path*}"` when `pathname` begins with `"/@"` and the unscoped template `"/{versioned}/{path*}"` otherwise), or `{ resolver, path }` when `resolver` is `"application"`.
