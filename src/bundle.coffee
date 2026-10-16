import Path from "node:path"
import FS from "node:fs/promises"
import JSZip from "jszip"
import { pipe } from "@dashkite/joy"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import Quotient from "./functors/quotient"
import Compiler from "./functors/compiler"
import BundleResolver from "./functors/resolver"
import preset from "./presets/node"

ZIP_OPTIONS =
  type: "nodebuffer"
  compression: "DEFLATE"
  compressionOptions:
    level: 9

checkManifest = ( directory ) ->
  path = Path.join directory, "package.json"
  try
    await FS.access path
    path
  catch error
    if error.code != "ENOENT"
      throw error
    null

scanManifest = ( directory ) ->
  current = directory
  while current && ( current != Path.dirname current )
    manifest = await checkManifest current
    if manifest?
      return manifest
    current = Path.dirname current
  null

findPackageManifest = ( path ) ->
  path = await FS.realpath path
  scanManifest Path.dirname path

extractPackageName = ( remainder ) ->
  parts = remainder.split "/"
  if remainder.startsWith "@"
    ( parts.slice 0, 2 ).join "/"
  else
    parts[ 0 ]

derivePackageBundleDirectory = ( path ) ->
  marker = "node_modules/"
  index = path.lastIndexOf marker
  if index == -1
    ""
  else
    Path.join ( path.slice 0, index + marker.length ),
      extractPackageName ( path.slice index + marker.length )

resolveSourceDiskPath = ( source, graph ) ->
  url = graph.sources.get source
  ( new URL url ).pathname

serializeDiagnostics = ( value ) ->
  replacer = ( key, item ) ->
    if item instanceof Set
      Array.from item
    else if item instanceof Map
      Object.fromEntries item
    else
      item
  JSON.stringify value, replacer, 2

writeDiagnosticFile = ( directory, filename, data ) ->
  path = Path.join directory, filename
  content = serializeDiagnostics data
  FS.writeFile path, content

deriveDiagnosticsDirectory = ( entries ) ->
  basename = Path.basename entries[ 0 ], Path.extname entries[ 0 ]
  Path.join process.cwd(), ".atlas", "bundle", basename

writePipelineDiagnostics = ( directory, pipeline ) ->
  { graph, components, index } = pipeline
  await FS.mkdir directory, recursive: true
  await writeDiagnosticFile directory, "module-graph.json", graph
  await writeDiagnosticFile directory, "component-graph.json", components
  await writeDiagnosticFile directory, "tree-index.json", index
  return

writeBundleDiagnostics = ( directory, map ) ->
  await writeDiagnosticFile directory, "bundle-map.json", map
  return

dumpDiagnostics = ( context ) ->
  if process.env.DEBUG
    try
      directory = deriveDiagnosticsDirectory context.entries
      await writePipelineDiagnostics directory, context.pipeline
      await writeBundleDiagnostics directory, context.pipeline.map
    catch
      null
  context

resolveEntryPaths = ( directory, entry ) ->
  relative = if Path.isAbsolute entry
    Path.relative directory, entry
  else
    entry
  absolute = Path.resolve directory, relative
  { relative, absolute }

resolveRootManifestPath = ( directory ) ->
  Path.resolve directory, "package.json"

readOptionalFile = ( path ) ->
  try
    FS.readFile path
  catch error
    if error.code != "ENOENT"
      throw error
    null

readRootManifest = ( directory ) ->
  path = resolveRootManifestPath directory
  readOptionalFile path

class BundleArchive
  @make: ( directory, graph ) ->
    Object.assign ( new @ ),
      zip: JSZip()
      directory: directory
      graph: graph
      destinations: new Set()
      packages: new Set()

  addFile: ( destination, path ) ->
    if !@destinations.has destination
      @destinations.add destination
      content = await FS.readFile path
      @zip.file destination, content
    return

  addEntry: ( entry ) ->
    { relative, absolute } = resolveEntryPaths @directory, entry
    await @addFile relative, absolute
    return

  addEntries: ( entries ) ->
    for entry in entries
      await @addEntry entry
    return

  addRootManifest: ->
    content = await readRootManifest @directory
    if content?
      @zip.file "package.json", content
      @destinations.add "package.json"
    return

  addPackageManifest: ( directory, path ) ->
    manifest = await findPackageManifest path
    if !manifest?
      throw new Error "Package manifest not found for #{ path }"
    destination = Path.join directory, "package.json"
    await @addFile destination, manifest
    return

  addDependencyManifest: ( destination, path ) ->
    directory = derivePackageBundleDirectory destination
    if directory != ""
      if !@packages.has directory
        @packages.add directory
        await @addPackageManifest directory, path
    return

  addBundleEntry: ( destination, source ) ->
    path = resolveSourceDiskPath source, @graph
    await @addDependencyManifest destination, path
    await @addFile destination, path
    return

  addBundleMap: ( map ) ->
    for [ destination, source ] from map
      await @addBundleEntry destination, source
    return

  generate: ->
    @zip.generateAsync ZIP_OPTIONS

constructArchive = ( context ) ->
  archive = BundleArchive.make context.options.directory,
    context.pipeline.graph
  await archive.addEntries context.entries
  await archive.addRootManifest()
  await archive.addBundleMap context.pipeline.map
  archive.generate()

normalizeEntries = ( entries ) ->
  if !entries?
    throw new Error "Entries argument is required"
  [ entries ].flat()

normalizeOptions = ( options ) ->
  directory = options.directory ? process.cwd()
  external = [ "@aws-sdk/*", ( options.external ? [] )... ]
  resolvers = options.resolvers ? preset
  { options..., directory, external, resolvers }

createContext = ( entries, options = {} ) ->
  entries: normalizeEntries entries
  options: normalizeOptions options

analyzeDependencies = ( context ) ->
  dependencies = analyze context.entries, {
    context.options...
    cwd: context.options.directory
    platform: "node"
    conditions: [ "node" ]
    external: context.options.external
  }
  { context..., dependencies }

ingestDependencies = ( dependencies, options ) ->
  ingest dependencies, {
    options...
    cwd: options.directory
  }

createPipeline = ( graph, components, index, map ) ->
  { graph, components, index, map }

applyFunctors = ( graph, options ) ->
  components = Quotient.apply graph
  index = Compiler.apply components, options.compact
  resolver = BundleResolver.make components, index, options.resolvers
  map = resolver.resolve()
  createPipeline graph, components, index, map

executeFunctors = ( context ) ->
  { dependencies, options } = context
  graph = await ingestDependencies dependencies, options
  pipeline = applyFunctors graph, options
  { context..., pipeline }

bundle = pipe [
  createContext
  analyzeDependencies
  executeFunctors
  dumpDiagnostics
  constructArchive
]

export default bundle
export { bundle }
