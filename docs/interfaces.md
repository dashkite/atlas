# Atlas Interfaces

This document defines the architectural boundaries for `@dashkite/atlas`.
For complete signatures and parameter descriptions, read [Reference](reference.md).

## Public Interface

The public interface contains the entry points exported to external consumers via `@dashkite/atlas`, `@dashkite/atlas/presets`, and `@dashkite/atlas/presets/*`, as well as the extension protocol for custom resolvers.
Callers and external plugin implementations at this boundary are untrusted.
Public entry points MUST validate preconditions and fail fast on contract violations, and protocol callers (`ResolverRegistry` / `MetaResolver`) MUST validate untrusted values returned by resolver protocol methods.

- **Compilation Pipelines**:
  - [`generate`](reference.md#generate): Generates an optimized WHATWG JavaScript import map (`{ imports, scopes }`) from one or more entry points.
  - [`bundle`](reference.md#bundle): Analyzes, ingests, and compiles the dependency graph for the given entry points into a compressed ZIP archive (`Buffer`) suitable for Node.js or AWS Lambda execution.
- **Configurable Resolvers (`Resolvers`)**:
  - [`Resolvers.Registry`](reference.md#registry): Central resolver registry (`Registry.register`, `Registry.get`, `Registry.make`) allowing clients to register custom or configured resolvers, control which resolver keys Atlas uses, and wrap configured resolvers in a contract-enforcing `MetaResolver` proxy.
  - [`Resolvers.Application`](reference.md#application): Factory (`Application.make`) configuring intra-application module resolution relative to `config.root`.
  - [`Resolvers.Local`](reference.md#local): Factory (`Local.make`) configuring local workspace or metarepo package resolution via `config.root` and `config.patterns`.
  - [`Resolvers.Node`](reference.md#node): Factory (`Node.make`) configuring `node_modules` package resolution relative to `config.root`.
  - [`Resolvers.CDN`](reference.md#cdn): Factory (`CDN.make`) configuring remote HTTP CDN resolution via URL Codex templates (`config.template`).
- **Resolver Protocol**:
  - [`match`](reference.md#resolver-protocol), [`encode`](reference.md#resolver-protocol), [`decode`](reference.md#resolver-protocol), [`resolve`](reference.md#resolver-protocol): The public extension protocol implemented by custom and built-in resolvers.
  - **Contract-Enforcing Proxy Boundary**: Because custom resolvers are external implementations, Atlas cannot rely on implementors to enforce protocol contracts, nor can protocol method responses be validated solely at construction or registration time. Values returned from resolver protocol methods (`match`, `encode`, `decode`, `resolve`) are external boundary inputs and MUST be validated by the contract-enforcing proxy (`ResolverRegistry` / `MetaResolver`). Built-in resolvers (`Application`, `Local`, `Node`, `CDN`) validate their configuration at construction time (`.make(config)`), while their protocol methods rely on the proxy to validate responses rather than duplicating defensive checks.
- **Environment Presets (`@dashkite/atlas/presets`, `@dashkite/atlas/presets/*`)**:
  - [`presets`](reference.md#presets) (`@dashkite/atlas/presets`): Exports `{ node, browser }` preset key arrays.
  - [`presets/node`](reference.md#presets) (`@dashkite/atlas/presets/node`): Registers default `application`, `local@default`, and `node` resolvers and exports `["application", "local@default", "node"]`.
  - [`presets/browser`](reference.md#presets) (`@dashkite/atlas/presets/browser`): Registers default `application`, `local@default`, `cdn@unpkg`, `cdn@jsdelivr`, and `cdn@esm` resolvers and exports `["application", "local@default", "cdn@unpkg"]`.
- **Canonical URL Codec (`AtlasURL`)**:
  - [`AtlasURL.encode`](reference.md#atlasurl) and [`AtlasURL.decode`](reference.md#atlasurl): Symmetrically encodes and decodes canonical `atlas://` URLs and dependency descriptors (`{ resolver, module, path }` or `{ resolver, path }`).

## Internal Interfaces

Internal interfaces represent boundaries between internal subsystems.
Callers at these boundaries are trusted.
These functions and classes operate on contract trust and MUST NOT duplicate defensive guards.

- **Dependency Analysis & Ingestion Subsystem (`src/helpers/analyze.coffee`, `src/helpers/module.coffee`, `src/ingest.coffee`)**:
  - `analyze` (`src/helpers/analyze.coffee`): Runs `esbuild` dependency discovery and yields dependency descriptors (`{ source, module, import }`).
  - `ModuleCache` (`src/helpers/module.coffee`): Instance-scoped upward directory scanner and cache for locating and normalizing nearest `package.json` manifests during `analyze`.
  - `ingest`, `entryPoint`, `ModuleURLResolver`, `ModuleGraphBuilder`
    (`src/ingest.coffee`): Consumes the dependency stream from `analyze`,
    deduplicates physical files by inode (`FS.stat`), matches dependencies
    against the configured `MetaResolver`, and constructs a `ModuleGraph`.
- **Category Data Structures (`src/categories/*`)**:
  - `ModuleGraph` (`src/categories/module-graph.coffee`): Directed multigraph storing canonical `atlas://` module vertices, `intra`/`inter` dependency edges, vertex attributes (`packageId`), and physical `file://` source URL mappings (`sources`).
  - `ComponentGraph` (`src/categories/component-graph.coffee`): Quotient graph grouping module vertices by `packageId` into package-level components with deduplicated inter-component edges.
  - `TreeIndex` (`src/categories/tree-index.coffee`): Hierarchical scope tree binding component paths to target package components for `node_modules` layout compilation.
  - `Trie` (`src/categories/trie.coffee`): Prefix tree representing hierarchical URL scopes and specifier bindings for import map transformations (`upsertPath`, `getSegments`, `getAddress`).
  - `Path` (`src/categories/path.coffee`): Tuple/array path utilities (`root`, `concat`, `isPrefix`) for `TreeIndex` scope paths.
- **Import Map Functor Pipeline (`src/functors/*`, `src/generate.coffee`)**:
  - `baseline` (`src/functors/baseline.coffee`): Projects inter-package edges from a `ModuleGraph` into a baseline scope `Trie`.
  - `compact` (`src/functors/compaction.coffee`): Lifts shared bindings up the scope `Trie` via post-order traversal without introducing shadowing conflicts.
  - `compress` (`src/functors/compression.coffee`): Collapses file-level bindings sharing common directory prefixes into trailing-slash prefix mappings.
  - `resolve` (`src/functors/resolution.coffee`): Translates canonical `atlas://` target bindings in the `Trie` into runtime URLs via the composite `MetaResolver`.
  - `serialize` (`src/functors/serialization.coffee`): Formats a resolved `Trie` into a WHATWG `{ imports, scopes }` import map object.
  - Pipeline orchestration helpers in `src/generate.coffee` (`prepareContext`, `executePipeline`, `applyFunctors`) and shared `Diagnostics` (`dump`) in `src/helpers/diagnostics.coffee`.
- **Application Bundling Functor Pipeline (`src/functors/*`, `src/bundle.coffee`, `src/helpers/*`)**:
  - `quotient` (`src/functors/quotient.coffee`): Contracts intra-package edges in a `ModuleGraph` to produce a `ComponentGraph`.
  - `compile` (`src/functors/compiler.coffee`): Embeds a `ComponentGraph` into a `TreeIndex`, hoisting non-conflicting components to `Path.root` when `compact` is enabled and isolating version collisions in nested scopes.
  - `resolve` / `BundleResolver` (`src/functors/resolver.coffee`): Projects a `ComponentGraph` and `TreeIndex` into a `Map<destinationPath, atlasUrl>` using `Directory` and memoized directory resolution on `BundleResolver`.
  - `Manifest` (`src/helpers/manifest.coffee`): Locates package manifests via Node's `Module.findPackageJSON` (`find`) and reads root manifests with `ENOENT` recovery returning `null` when absent (`read`).
  - `BundleArchive` and `Package` (`src/helpers/archive.coffee`): Assembles the DEFLATE-compressed ZIP `Buffer` with entry files, package manifests, and dependencies.
  - `Diagnostics` (`src/helpers/diagnostics.coffee`): Provides shared `DEBUG` pipeline artifact serialization and disk persistence (`dump`).
  - Pipeline coordination helpers in `src/bundle.coffee` (`Entry`, `normalizeOptions`, `prepareContext`, `applyFunctors`, `executePipeline`).
- **Built-In Resolver Implementations & Inspection Helpers (`src/resolvers/*`, `src/url.coffee`, `src/helpers/inspector.coffee`)**:
  - `ApplicationResolver`, `LocalResolver`, `NodeResolver`, `CDNResolver` protocol implementations (`match`, `encode`, `decode`, `resolve`) and internal formatting/template helpers: Operate on trusted pipeline inputs and rely on the `ResolverRegistry` (`MetaResolver`) proxy to enforce protocol postconditions.
  - `BundleInspector` (`src/helpers/inspector.coffee`): Diagnostic and testing utility (`make`, `fromZip`, `fromMap`, `getFiles`, `findInstancesOf`, `countInstancesOf`, `hasFile`) for inspecting package instances and file paths in bundle maps and ZIP buffers.

## Boundary Evolution

Boundaries are fluid during active development.
Authors MAY adjust boundaries provided they update the Contract Triad in lockstep:
1. Code: Add boundary precondition checks (or proxy postcondition checks for extension protocols) when promoting to public, or remove defensive guards when demoting to internal.
2. Tests: Update boundary rejection tests and postcondition assertions in the corresponding test module.
3. Documentation: Update both `docs/interfaces.md` and `docs/reference.md`.
