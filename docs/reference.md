# Reference

## Pipeline Functions

All pipeline functions operate relative to a target package working directory (`options.cwd`), and entry-point pipelines (`analyze`, `generate`, `bundle`) additionally accept an optional entry-point base directory (`options.source`).

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

### analyze

$analyze: [entries, options] \dashrightarrow reactor$

Analyzes the module dependencies for the given entry points using `esbuild` (via a mock build targeting `/dev/null` with `metafile: true`). Returns an asynchronous generator (reactor) yielding dependency objects `{ source, module, import }`.

- **`entries`** *(Array\<String\>)*: Array of entry point file paths, each resolved via `Path.resolve(source, entry)`.
- **`options`** *(Object, optional)*:
  - **`cwd`** *(String, default: `process.cwd()`)*: Working directory passed to `esbuild` (`absWorkingDir`) and `ModuleCache.make(cwd)`. All emitted `metafile.inputs` paths are relative to `cwd`.
  - **`source`** *(String, default: `options.cwd`)*: Base directory used to resolve input `entries` (`Path.resolve(cwd, options.source ? ".")`).
  - **`platform`** *(String, default: `"node"`)*: Target platform for `esbuild`.
  - **`conditions`** *(Array\<String\>, default: `[ platform ]`)*: Export conditions for package resolution.
  - **`external`** *(Array\<String\>, default: `[]`)*: External module specifiers (`"esbuild"` is always included).

### ingest

$ingest: [dependencies, options] \dashrightarrow ModuleGraph$

Consumes the asynchronous dependency stream from `analyze`, deduplicates physical files by inode (`fs.stat(path).ino`), matches each dependency against the configured resolvers, and returns a populated `ModuleGraph` (including `graph.sources` mapping canonical `atlas://` URLs to physical `file://` URLs).

- **`dependencies`** *(AsyncIterable\<Object\> | Array\<Object\>)*: Dependency items yielded by `analyze`.
- **`options`** *(Object, optional)*:
  - **`cwd`** *(String, default: `process.cwd()`)*: Base directory used to resolve relative dependency paths on disk and passed in `context = { source, cwd }` to `resolver.match(context)`.
  - **`resolvers`** *(Array\<String\>, default: `presets/node`)*: Registered resolver keys used to construct the composite Meta Resolver.

---

## Resolvers

Resolvers translate between dependency descriptors, canonical `atlas://` URLs, and target runtime URLs (`file://` or `https://`). Unlike pipeline functions (which take `cwd` and `source`), filesystem-backed resolvers accept **`root`** in their `.make(config)` factory configuration.

### Registry

- $Registry.register: [key, resolver] \to resolver$ — Registers a configured resolver instance under `key` (e.g., `"local@workspace"` or `"cdn@jsdelivr"`).
- $Registry.get: [key] \to resolver$ — Retrieves a registered resolver instance by `key`.
- $Registry.make: [keys] \to metaResolver$ — Creates a composite Meta Resolver dispatching across the ordered array of `keys`.

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

- **`@dashkite/atlas/presets/node`**: Registers default `application`, `local@default` (`root: process.cwd()`), and `node` resolvers, and exports `["application", "local@default", "node"]`.
- **`@dashkite/atlas/presets/browser`**: Registers default `application`, `local@default`, `cdn@unpkg`, `cdn@jsdelivr`, and `cdn@esm` resolvers, and exports `["application", "local@default", "cdn@unpkg"]`.

---

## AtlasURL

`AtlasURL` provides inverse encoding and decoding functions for canonical `atlas://` URLs:

- $AtlasURL.encode: [descriptor] \to url$ — Formats a dependency descriptor (`{ resolver, module, path }`) into a canonical `atlas://` URL string.
- $AtlasURL.decode: [url] \to descriptor$ — Decodes a canonical `atlas://` module URL string into `{ resolver, module: { scope, name, version }, path }`, checking the scoped URL Codex pathname template (`"/{scope}/{versioned}/{path*}"`) first and falling back to the unscoped template (`"/{versioned}/{path*}"`).
- $AtlasURL.parse: [url] \to \{ resolver, pathname \}$ — Parses the resolver key (`username@hostname` or `hostname`) and raw `pathname` from an `atlas://` URL string.
- $AtlasURL.format: [descriptor] \to url$ — Alias for `AtlasURL.encode`.

