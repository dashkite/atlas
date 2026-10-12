import { test } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import FS from "node:fs/promises"
import Path from "node:path"

tests = ( path, parameters... ) ->
  module = await import( "./#{path}" )
  module.default parameters...

SUITES = [
  [ "AtlasURL", "url" ]
  [ "Ingest", "ingest" ]
  [ "Inspector", "inspector" ]
  [ "Bundle", "bundle" ]
  [ "Generate", "generate" ]

  [ "ModuleGraph", "categories/module-graph" ]
  [ "ComponentGraph", "categories/component-graph" ]
  [ "Path", "categories/path" ]
  [ "TreeIndex", "categories/tree-index" ]

  [ "Quotient Functor", "functors/quotient" ]
  [ "Compiler Functor", "functors/compiler" ]
  [ "Resolver Functor", "functors/resolver" ]
  [ "Resolvers", "resolvers" ]
  [ "Baseline Functor", "functors/baseline" ]
  [ "Compaction Functor", "functors/compaction" ]
  [ "Compression Functor", "functors/compression" ]
  [ "Resolution Functor", "functors/resolution" ]
  [ "Serialization", "functors/serialization" ]
]

cleanEnvironment = ->
  if !process.env.DEBUG
    return
  try
    await FS.rm ( Path.join process.cwd(), ".atlas" ),
      recursive: true
      force: true
  catch
    null

loadSuite = ( [ name, path ] ) ->
  test name, await tests path

executeTestSuite = ->
  cases = []
  for entry in SUITES
    cases.push ( await loadSuite entry )
  print await test "Atlas", cases

do ->
  await cleanEnvironment()
  await executeTestSuite()