import Path from "node:path"
import FS from "node:fs/promises"
import Ajv from "ajv"
import { pipe } from "@dashkite/joy"
import {
  isSet, isMap, isSymbol, isString, isArray
} from "@dashkite/joy/type"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import baseline from "./functors/baseline"
import compact from "./functors/compaction"
import compress from "./functors/compression"
import resolve from "./functors/resolution"
import serialize from "./functors/serialization"
import browserPreset from "./presets/browser"
import nodePreset from "./presets/node"

Presets =
  Browser: browserPreset
  Node: nodePreset

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
    if key == "parent"
      undefined
    else if isSet value
      Array.from value
    else if isMap value
      Object.fromEntries value
    else if isSymbol value
      value.toString()
    else
      value

  serialize: ( value ) ->
    JSON.stringify value, Diagnostics.replacer, 2

  writeFile: ( directory, filename, data ) ->
    FS.writeFile ( Path.join directory, filename ),
      Diagnostics.serialize data

  deriveDirectory: ( entries ) ->
    basename = Path.basename entries[ 0 ], Path.extname entries[ 0 ]
    Path.join process.cwd(), ".atlas", "generate", basename

  tasks: ( directory, state ) ->
    pipeline = state.pipeline ? state
    ( Diagnostics.files pipeline ).map ([ filename, data ]) ->
      Diagnostics.writeFile directory, filename, data

  write: ( directory, state ) ->
    if process.env.DEBUG
      try
        await FS.mkdir directory, recursive: true
        await Promise.all ( Diagnostics.tasks directory, state )
      catch error
        console.warn "Atlas DEBUG: Failed to write debug files:", error
    return

dumpDiagnostics = ( state ) ->
  if process.env.DEBUG
    directory =
      if ( state.entries? ) && ( state.entries.length > 0 )
        Diagnostics.deriveDirectory state.entries
      else
        Path.join ( state.options?.cwd ? process.cwd() ), ".atlas-debug"
    await Diagnostics.write directory, state
  state

ajv = new Ajv()

validateOptions = ajv.compile
  type: "object"
  properties:
    cwd:
      type: "string"
      minLength: 1
    source:
      type: "string"
      minLength: 1
    resolvers:
      type: "array"
      minItems: 1
      items:
        type: "string"
        minLength: 1
    external:
      type: "array"
      items:
        type: "string"

isValidEntries = ( entries ) ->
  if isString entries
    entries.length > 0
  else if isArray entries
    ( entries.length > 0 ) && ( entries.every ( entry ) ->
      ( isString entry ) && ( entry.length > 0 )
    )
  else
    false

normalizeEntries = ( entries ) ->
  if isValidEntries entries
    [ entries ].flat()
  else
    throw new Error (
      "Entries must be a non-empty string or array of non-empty strings"
    )

normalizeOptions = ( options = {}) ->
  if validateOptions options
    cwd = Path.resolve ( options.cwd ? process.cwd() )
    resolvers = options.resolvers ? Presets.Browser
    external = options.external ? []
    source =
      if options.source?
        Path.resolve cwd, options.source
      else
        cwd
    { options..., cwd, source, resolvers, external }
  else
    throw new Error "Invalid generate options"

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