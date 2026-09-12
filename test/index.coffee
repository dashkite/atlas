import { test } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import testModuleGraph from "./categories/module-graph"
import testComponentGraph from "./categories/component-graph"
import testPath from "./categories/path"
import testTreeIndex from "./categories/tree-index"

import testQuotient from "./functors/quotient"
import testCompiler from "./functors/compiler"
import testResolver from "./functors/resolver"

import testUrl from "./url"
import testResolvers from "./resolvers"
import testIngest from "./ingest"
import testInspector from "./inspector"

do ->
  print await test "AtlasURL", testUrl()
  print await test "Ingest", testIngest()
  print await test "BundleInspector", testInspector()

  print await test "ModuleGraph", testModuleGraph()
  print await test "ComponentGraph", testComponentGraph()
  print await test "Path", testPath()
  print await test "TreeIndex", testTreeIndex()

  print await test "Quotient Functor", testQuotient()
  print await test "Compiler Functor", testCompiler()
  print await test "Resolver Functor", testResolver()
  print await test "Resolvers", testResolvers()
