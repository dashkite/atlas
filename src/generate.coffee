import Path from "node:path"
import FS from "node:fs/promises"
import { pipe } from "@dashkite/joy"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import baseline from "./functors/baseline"
import compact from "./functors/compaction"
import compress from "./functors/compression"
import resolve from "./functors/resolution"
import serialize from "./functors/serialization"
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
  FS.writeFile ( Path.join directory, filename ),
    serializeDiagnostics data

deriveDiagnosticsDirectory = ( entries ) ->
  basename = Path.basename entries[ 0 ], Path.extname entries[ 0 ]
  Path.join process.cwd(), ".atlas", "generate", basename

writePipelineDiagnostics = ( directory, pipeline ) ->
  try
    await FS.mkdir directory, recursive: true
    for [ filename, key ] from DIAGNOSTIC_FILES
      await writeDiagnosticFile directory, filename, pipeline[ key ]
  catch error
    console.warn "Failed to write pipeline diagnostics: #{ error.message }"
  return

dumpDiagnostics = ( context ) ->
  if process.env.DEBUG
    directory = deriveDiagnosticsDirectory context.entries
    await writePipelineDiagnostics directory, context.pipeline
  context

normalizeEntries = ( entries ) ->
  [ entries ].flat()

normalizeOptions = ( options ) ->
  cwd = options.cwd ? process.cwd()
  source = Path.resolve cwd, ( options.source ? "." )
  external = [ "@aws-sdk/*", ( options.external ? [] )... ]
  resolvers = options.resolvers ? nodePreset
  { options..., cwd, source, external, resolvers }

createContext = ( entries, options = {} ) ->
  entries: normalizeEntries entries
  options: normalizeOptions options

analyzeDependencies = ( context ) ->
  dependencies = analyze context.entries, {
    context.options...
    platform: "node"
    conditions: [ "node" ]
  }
  { context..., dependencies }

applyBaseline = ( state ) ->
  { state..., baselineTrie: baseline state.moduleGraph }

applyCompaction = ( state ) ->
  { state..., compactedTrie: compact state.baselineTrie }

applyCompression = ( state ) ->
  { state..., compressedTrie: compress state.compactedTrie }

buildTries = pipe [
  applyBaseline
  applyCompaction
  applyCompression
]

applyResolution = ( state ) ->
  {
    state...
    resolvedTrie: resolve state.compressedTrie, state.resolvers
  }

applySerialization = ( state ) ->
  {
    state...
    importMap: serialize state.resolvedTrie, state.resolvers
  }

resolveAndSerialize = pipe [
  applyResolution
  applySerialization
]

createFunctorContext = ( moduleGraph, resolvers ) ->
  { moduleGraph, resolvers }

applyFunctors = pipe [
  createFunctorContext
  buildTries
  resolveAndSerialize
]

executePipeline = ( context ) ->
  { dependencies, options } = context
  moduleGraph = await ingest dependencies, options
  pipeline = applyFunctors moduleGraph, options.resolvers
  { context..., pipeline }

extractImportMap = ( context ) ->
  context.pipeline.importMap

generate = pipe [
  createContext
  analyzeDependencies
  executePipeline
  dumpDiagnostics
  extractImportMap
]

export default generate
export { generate }