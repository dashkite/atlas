import { test } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import FS from "node:fs/promises"
import Path from "node:path"

tests = ( path, parameters... ) ->
  module = await import( "./#{path}" )
  module.default parameters...

do ->
  if process.env.DEBUG
    try
      await FS.rm Path.join(process.cwd(), ".atlas"), recursive: true, force: true
    catch
      null

  print await test "Atlas", [
    test "AtlasURL", await tests "url"
    test "Ingest", await tests "ingest"
    test "BundleInspector", await tests "inspector"
    test "Bundle", await tests "bundle"
    test "Generate", await tests "generate"

    test "ModuleGraph", await tests "categories/module-graph"
    test "ComponentGraph", await tests "categories/component-graph"
    test "Path", await tests "categories/path"
    test "TreeIndex", await tests "categories/tree-index"

    test "Quotient Functor", await tests "functors/quotient"
    test "Compiler Functor", await tests "functors/compiler"
    test "Resolver Functor", await tests "functors/resolver"
    test "Resolvers", await tests "resolvers"
    test "Baseline Functor", await tests "functors/baseline"
    test "Compaction Functor", await tests "functors/compaction"
    test "Compression Functor", await tests "functors/compression"
    test "Resolution Functor", await tests "functors/resolution"
    test "Serialization", await tests "functors/serialization"
  ]
