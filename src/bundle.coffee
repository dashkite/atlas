import Path from "node:path"
import AJV from "ajv"
import { pipe } from "@dashkite/joy"
import { isString, isArray } from "@dashkite/joy/type"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import quotient from "./functors/quotient"
import compile from "./functors/compiler"
import resolve from "./functors/resolver"
import preset from "./presets/node"
import Diagnostics from "./helpers/diagnostics"
import BundleArchive from "./helpers/archive"

Entry =
  isValid: ( entries ) ->
    if isString entries
      entries.length > 0
    else if isArray entries
      ( entries.length > 0 ) && ( entries.every ( entry ) ->
        ( isString entry ) && ( entry.length > 0 )
      )
    else
      false

  normalize: ( entries ) ->
    if Entry.isValid entries
      [ entries ].flat()
    else
      throw new Error "Entries argument is required"

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
    compact:
      type: "boolean"
    external:
      type: "array"
      items:
        type: "string"

normalizeOptions = ( options ) ->
  if validateOptions options
    cwd = Path.resolve ( options.cwd ? process.cwd() )
    resolvers = options.resolvers ? preset
    external = [ "@aws-sdk/*", ( options.external ? [])... ]
    source = Path.resolve cwd, ( options.source ? "." )
    { options..., cwd, source, resolvers, external }
  else
    throw new Error "Invalid bundle options"

createContext = ( entries, options = {}) ->
  entries: Entry.normalize entries
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

applyFunctors = ( graph, options ) ->
  components = quotient graph
  index = compile components, options
  map = resolve components, index, options.resolvers
  { graph, components, index, map }

executePipeline = ( context ) ->
  graph = await ingest context.dependencies, context.options
  pipeline = applyFunctors graph, context.options
  { context..., pipeline }

selectArtifacts = ({ graph, components, index, map }) ->
  "module-graph.json": graph
  "component-graph.json": components
  "tree-index.json": index
  "bundle-map.json": map

bundle = pipe [
  prepareContext
  executePipeline
  Diagnostics.dump "bundle", selectArtifacts
  BundleArchive.construct
]

export default bundle
export { bundle }
