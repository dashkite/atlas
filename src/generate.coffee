import Path from "node:path"
import AJV from "ajv"
import { pipe } from "@dashkite/joy"
import analyze from "./helpers/analyze"
import normalizeEntries from "./helpers/entries"
import ingest from "./ingest"
import baseline from "./functors/baseline"
import compact from "./functors/compaction"
import compress from "./functors/compression"
import resolve from "./functors/resolution"
import serialize from "./functors/serialization"
import presets from "./presets"
import Diagnostics from "./helpers/diagnostics"

ajv = new AJV()

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

normalizeOptions = ( options ) ->
  if validateOptions options
    cwd = Path.resolve ( options.cwd ? process.cwd() )
    resolvers = options.resolvers ? presets.browser
    external = options.external ? []
    source = Path.resolve cwd, ( options.source ? "." )
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

applyFunctors = ( graph, resolvers ) ->
  initial = baseline graph
  compacted = compact initial
  compressed = compress compacted
  resolved = resolve compressed, resolvers
  importMap = serialize resolved, resolvers
  { graph, baseline: initial, compacted, compressed, resolved, importMap }

executePipeline = ( context ) ->
  graph = await ingest context.dependencies, context.options
  pipeline = applyFunctors graph, context.options.resolvers
  { context..., pipeline }

selectArtifacts = ( pipeline ) ->
  "module-graph.json": pipeline.graph
  "baseline-trie.json": pipeline.baseline
  "compacted-trie.json": pipeline.compacted
  "compressed-trie.json": pipeline.compressed
  "resolved-trie.json": pipeline.resolved
  "importmap.json": pipeline.importMap

extractImportMap = ( context ) ->
  context.pipeline.importMap

generate = pipe [
  prepareContext
  executePipeline
  Diagnostics.dump "generate", selectArtifacts
  extractImportMap
]

export default generate
export { generate }
