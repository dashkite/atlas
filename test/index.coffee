import { test } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import FS from "node:fs/promises"
import Path from "node:path"

import url from "./url"
import ingest from "./ingest"
import inspector from "./inspector"
import bundle from "./bundle"
import generate from "./generate"
import moduleGraph from "./categories/module-graph"
import componentGraph from "./categories/component-graph"
import path from "./categories/path"
import treeIndex from "./categories/tree-index"
import trie from "./categories/trie"
import quotient from "./functors/quotient"
import compiler from "./functors/compiler"
import resolver from "./functors/resolver"
import resolvers from "./resolvers"
import baseline from "./functors/baseline"
import compaction from "./functors/compaction"
import compression from "./functors/compression"
import resolution from "./functors/resolution"
import serialization from "./functors/serialization"

clean = ->
  if process.env.DEBUG
    try
      await FS.rm ( Path.join process.cwd(), ".atlas-debug" ),
        recursive: true
        force: true
  return

# [dust bunny] exemption from amen-declarative-suite:
# @dashkite/amen 0.9.30 returns Promise without .and
do ->
  await clean()
  print await test "Atlas", [
    test "AtlasURL", url()
    test "Ingest", ingest()
    test "Inspector", inspector()
    test "Bundle", bundle()
    test "Generate", generate()
    test "ModuleGraph", moduleGraph()
    test "ComponentGraph", componentGraph()
    test "Path", path()
    test "TreeIndex", treeIndex()
    test "Trie", trie()
    test "Quotient Functor", quotient()
    test "Compiler Functor", compiler()
    test "Resolver Functor", resolver()
    test "Resolvers", resolvers()
    test "Baseline Functor", baseline()
    test "Compaction Functor", compaction()
    test "Compression Functor", compression()
    test "Resolution Functor", resolution()
    test "Serialization", serialization()
  ]