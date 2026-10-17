# Testing

This document describes the testing approach for Atlas.

## General Approach

The test suite leverages `@dashkite/amen` to structure test hierarchies and `@dashkite/assert` to validate category structures, functor transformations, resolver behaviors, import maps, and ZIP bundles. The test suites in `test/index.coffee` cover:

- **End-to-End Pipelines**:
  - `Bundle` (`test/bundle.coffee`): Verifies ZIP bundle generation with absolute entry points, `cwd`-relative entry points, and entry points resolved relative to `options.source` (`{ cwd, source }`).
  - `Generate` (`test/generate.coffee`): Verifies WHATWG import map generation using the browser preset both with explicit paths and with `{ cwd, source }`.
  - `Ingest` (`test/ingest.coffee`): Verifies physical file deduplication across hard links via inode caching (`cwd`).
  - `Inspector` (`test/inspector.coffee`): Verifies `BundleInspector` package instance counting on maps and ZIP archives.
- **Resolvers & URL Scheme**:
  - `AtlasURL` (`test/url.coffee`): Verifies parsing and formatting of `atlas://` URLs.
  - `Resolvers` (`test/resolvers.coffee`): Verifies `Registry`, composite Meta Resolver validation, `Application`, `Node`, `CDN`, `Local` (`{ root, patterns }`), and `presets`.
- **Categories & Functors**:
  - Category data structures (`ModuleGraph`, `ComponentGraph`, `Path`, `TreeIndex`).
  - Bundling functors (`Quotient`, `Compiler`, `BundleResolver`).
  - Import map functors (`baseline`, `Compaction`, `Compression`, `Resolution`, `Serialization`).

## Running Tests

To run the test suite, invoke the following command:

```bash
npx genie test
```
