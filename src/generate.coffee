import Path from "node:path"
import FS from "node:fs/promises"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import Baseline from "./functors/baseline"
import Compaction from "./functors/compaction"
import Compression from "./functors/compression"
import Resolution from "./functors/resolution"
import Serialization from "./functors/serialization"
import nodePreset from "./presets/node"

generate = ( entries, options = {} ) ->
  entries = [ entries ] if typeof entries == "string"
  cwd = options.cwd ? options.root ? process.cwd()

  external = [ "@aws-sdk/*", ( options.external ? [] )... ]

  deps = analyze entries, {
    options...
    cwd
    platform: "node"
    conditions: [ "node" ]
    external
  }

  resolvers = options.resolvers ? nodePreset

  # The Categorical Pipeline
  moduleGraph = await ingest deps, { options..., cwd, root: cwd, resolvers }
  
  baselineTrie = Baseline.apply moduleGraph
  compactedTrie = Compaction.apply baselineTrie
  compressedTrie = Compression.apply compactedTrie
  resolvedTrie = Resolution.apply compressedTrie, resolvers
  importMap = Serialization.apply resolvedTrie, resolvers

  if process.env.DEBUG
    entryBasename = Path.basename entries[0], Path.extname entries[0]
    diagDir = Path.join process.cwd(), ".atlas", "generate", entryBasename
    try
      await FS.mkdir diagDir, recursive: true
      replacer = (key, value) ->
        if key == "parent" then return undefined
        if value instanceof Set then Array.from(value)
        else if value instanceof Map then Object.fromEntries(value)
        else if typeof value == "symbol" then value.toString()
        else value

      await FS.writeFile Path.join(diagDir, "module-graph.json"), JSON.stringify(moduleGraph, replacer, 2)
      await FS.writeFile Path.join(diagDir, "baseline-trie.json"), JSON.stringify(baselineTrie, replacer, 2)
      await FS.writeFile Path.join(diagDir, "compacted-trie.json"), JSON.stringify(compactedTrie, replacer, 2)
      await FS.writeFile Path.join(diagDir, "compressed-trie.json"), JSON.stringify(compressedTrie, replacer, 2)
      await FS.writeFile Path.join(diagDir, "resolved-trie.json"), JSON.stringify(resolvedTrie, replacer, 2)
      await FS.writeFile Path.join(diagDir, "importmap.json"), JSON.stringify(importMap, null, 2)
    catch err
      console.warn "Atlas Diagnostics: Failed to emit state to .atlas -", err.message

  importMap

export default generate
export { generate }
