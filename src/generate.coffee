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

DIAGNOSTIC_FILES = [
  [ "module-graph.json", "moduleGraph" ]
  [ "baseline-trie.json", "baselineTrie" ]
  [ "compacted-trie.json", "compactedTrie" ]
  [ "compressed-trie.json", "compressedTrie" ]
  [ "resolved-trie.json", "resolvedTrie" ]
  [ "importmap.json", "importMap" ]
]

diagnosticReplacer = ( key, value ) ->
  if key == "parent" then return undefined
  if value instanceof Set then return Array.from value
  if value instanceof Map then return Object.fromEntries value
  if typeof value == "symbol" then return value.toString()
  value

serializeDiagnostics = ( value ) ->
  JSON.stringify value, diagnosticReplacer, 2

writeDiagnosticFile = ( directory, filename, data ) ->
  filePath = Path.join directory, filename
  content = serializeDiagnostics data
  FS.writeFile filePath, content

deriveDiagnosticsDirectory = ( entries ) ->
  entryBasename = Path.basename entries[ 0 ], Path.extname entries[ 0 ]
  Path.join process.cwd(), ".atlas", "generate", entryBasename

writePipelineDiagnostics = ( directory, pipeline ) ->
  try
    await FS.mkdir directory, recursive: true
    for [ filename, key ] from DIAGNOSTIC_FILES
      await writeDiagnosticFile directory, filename, pipeline[ key ]
  catch error
    warningMessage = "Atlas Diagnostics: Failed to emit state to .atlas -"
    console.warn warningMessage, error.message
  return

dumpDiagnostics = ( entries, pipeline ) ->
  if process.env.DEBUG
    diagnosticsDirectory = deriveDiagnosticsDirectory entries
    await writePipelineDiagnostics diagnosticsDirectory, pipeline
  return

normalizeEntries = ( entries ) ->
  if typeof entries == "string"
    [ entries ]
  else
    entries

normalizeOptions = ( options ) ->
  cwd = options.cwd ? options.root ? process.cwd()
  external = [ "@aws-sdk/*", ( options.external ? [] )... ]
  resolvers = options.resolvers ? nodePreset
  { options..., cwd, root: cwd, external, resolvers }

analyzeDependencies = ( entries, options ) ->
  analyze entries, {
    options...
    cwd: options.cwd
    platform: "node"
    conditions: [ "node" ]
    external: options.external
  }

buildTries = ( moduleGraph ) ->
  baselineTrie = Baseline.apply moduleGraph
  compactedTrie = Compaction.apply baselineTrie
  compressedTrie = Compression.apply compactedTrie
  { baselineTrie, compactedTrie, compressedTrie }

resolveAndSerialize = ( compressedTrie, resolvers ) ->
  resolvedTrie = Resolution.apply compressedTrie, resolvers
  importMap = Serialization.apply resolvedTrie, resolvers
  { resolvedTrie, importMap }

applyFunctors = ( moduleGraph, resolvers ) ->
  tries = buildTries moduleGraph
  resolution = resolveAndSerialize tries.compressedTrie, resolvers
  { moduleGraph, tries..., resolution... }

executePipeline = ( dependencies, options ) ->
  moduleGraph = await ingest dependencies, options
  applyFunctors moduleGraph, options.resolvers

generate = ( entries, options = {} ) ->
  normalizedEntries = normalizeEntries entries
  normalizedOptions = normalizeOptions options
  dependencies = analyzeDependencies normalizedEntries, normalizedOptions
  pipeline = await executePipeline dependencies, normalizedOptions
  await dumpDiagnostics normalizedEntries, pipeline
  pipeline.importMap

export default generate
export { generate }