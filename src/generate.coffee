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
import preset from "./presets/node"

Diagnostics =
  files: ( pipeline ) -> [
    [ "module-graph.json", pipeline.graph ]
    [ "baseline-trie.json", pipeline.tries.baseline ]
    [ "compacted-trie.json", pipeline.tries.compacted ]
    [ "compressed-trie.json", pipeline.tries.compressed ]
    [ "resolved-trie.json", pipeline.tries.resolved ]
    [ "importmap.json", pipeline.importMap ]
  ]

  replacer: ( key, value ) ->
    if key == "parent" then return undefined
    if value instanceof Set then return Array.from value
    if value instanceof Map then return Object.fromEntries value
    if typeof value == "symbol" then return value.toString()
    value

  serialize: ( value ) ->
    JSON.stringify value, Diagnostics.replacer, 2

  writeFile: ( directory, filename, data ) ->
    FS.writeFile ( Path.join directory, filename ),
      Diagnostics.serialize data

  deriveDirectory: ( entries ) ->
    basename = Path.basename entries[ 0 ], Path.extname entries[ 0 ]
    Path.join process.cwd(), ".atlas", "generate", basename

  write: ( directory, pipeline ) ->
    try
      await FS.mkdir directory, recursive: true
      for [ filename, data ] from Diagnostics.files pipeline
        await Diagnostics.writeFile directory, filename, data
    catch error
      console.warn "Failed to write pipeline diagnostics: #{ error.message }"
    return

dumpDiagnostics = ( context ) ->
  if process.env.DEBUG
    directory = Diagnostics.deriveDirectory context.entries
    await Diagnostics.write directory, context.pipeline
  context

normalizeEntries = ( entries ) ->
  [ entries ].flat()

normalizeOptions = ( options ) ->
  cwd = options.cwd ? process.cwd()
  source = Path.resolve cwd, ( options.source ? "." )
  external = [ "@aws-sdk/*", ( options.external ? [])... ]
  resolvers = options.resolvers ? preset
  { options..., cwd, source, external, resolvers }

createContext = ( entries, options = {}) ->
  entries: normalizeEntries entries
  options: normalizeOptions options

analyzeDependencies = ( context ) ->
  dependencies = analyze context.entries, {
    context.options...
    platform: "node"
    conditions: [ "node" ]
  }
  { context..., dependencies }

prepareContext = pipe [
  createContext
  analyzeDependencies
]

applyBaseline = ( state ) ->
  tries = { state.tries..., baseline: baseline state.graph }
  { state..., tries }

applyCompaction = ( state ) ->
  tries = { state.tries..., compacted: compact state.tries.baseline }
  { state..., tries }

applyCompression = ( state ) ->
  tries = { state.tries..., compressed: compress state.tries.compacted }
  { state..., tries }

buildTries = pipe [
  applyBaseline
  applyCompaction
  applyCompression
]

applyResolution = ( state ) ->
  tries = {
    state.tries...
    resolved: resolve state.tries.compressed, state.resolvers
  }
  { state..., tries }

applySerialization = ( state ) ->
  {
    state...
    importMap: serialize state.tries.resolved, state.resolvers
  }

resolveAndSerialize = pipe [
  applyResolution
  applySerialization
]

createState = ( graph, resolvers ) ->
  { graph, resolvers, tries: {}}

applyFunctors = pipe [
  createState
  buildTries
  resolveAndSerialize
]

ingestDependencies = ( context ) ->
  {
    context...
    graph: await ingest context.dependencies, context.options
  }

runFunctors = ( context ) ->
  {
    context...
    pipeline: applyFunctors context.graph, context.options.resolvers
  }

executePipeline = pipe [
  ingestDependencies
  runFunctors
]

extractImportMap = ( context ) ->
  context.pipeline.importMap

generate = pipe [
  prepareContext
  executePipeline
  dumpDiagnostics
  extractImportMap
]

export default generate
export { generate }