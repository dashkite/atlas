import Path from "node:path"
import FS from "node:fs/promises"
import JSZip from "jszip"
import { pipe } from "@dashkite/joy"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import Quotient from "./functors/quotient"
import Compiler from "./functors/compiler"
import Resolver from "./functors/resolver"
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
    if item?.add?
      Array.from item
    else if item?.set?
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
    directory = deriveDiagnosticsDirectory context.entries
    await writePipelineDiagnostics directory, context.pipeline
    await writeBundleDiagnostics directory, context.pipeline.bundleMap
  context

resolveEntryPaths = ( directory, entry ) ->
  relative = if Path.isAbsolute entry
    Path.relative directory, entry
  else
    entry
  absolute = Path.resolve directory, relative
  { relative, absolute }

archiveEntry = ( context, entry ) ->
  { relative, absolute } = resolveEntryPaths context.directory, entry
  await archiveFile context, relative, absolute
  return

archiveEntries = ( context, entries ) ->
  for entry in entries
    await archiveEntry context, entry
  return

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

archiveRootManifest = ( context ) ->
  { zip, directory, destinations } = context
  content = await readRootManifest directory
  if content?
    zip.file "package.json", content
    destinations.add "package.json"
  return

archiveFile = ( context, destination, path ) ->
  { zip, destinations } = context
  if !destinations.has destination
    destinations.add destination
    content = await FS.readFile path
    zip.file destination, content
  return

archivePackageManifest = ( context, directory, path ) ->
  manifest = await findPackageManifest path
  if !manifest?
    throw new Error "Package manifest not found for #{ path }"
  destination = Path.join directory, "package.json"
  await archiveFile context, destination, manifest
  return

archiveDependencyManifest = ( context, destination, path ) ->
  { packages } = context
  directory = derivePackageBundleDirectory destination
  if directory != ""
    if !packages.has directory
      packages.add directory
      await archivePackageManifest context, directory, path
  return

archiveBundleEntry = ( context, destination, source ) ->
  path = resolveSourceDiskPath source, context.graph
  await archiveDependencyManifest context, destination, path
  await archiveFile context, destination, path
  return

archiveBundleMap = ( context, map ) ->
  for [ destination, source ] from map
    await archiveBundleEntry context, destination, source
  return

createArchiveContext = ( directory, graph ) ->
  zip: JSZip()
  directory: directory
  cwd: directory
  graph: graph
  moduleGraph: graph
  destinations: new Set()
  packages: new Set()

constructArchive = ( context ) ->
  archive = createArchiveContext context.options.cwd,
    context.pipeline.graph
  await archiveEntries archive, context.entries
  await archiveRootManifest archive
  await archiveBundleMap archive, context.pipeline.map
  archive.zip.generateAsync ZIP_OPTIONS

normalizeEntries = ( entries ) ->
  [ entries ].flat()

normalizeOptions = ( options ) ->
  cwd = options.cwd ? process.cwd()
  external = [ "@aws-sdk/*", ( options.external ? [] )... ]
  resolvers = options.resolvers ? preset
  { options..., cwd, external, resolvers }

createContext = ( entries, options = {} ) ->
  entries: normalizeEntries entries
  options: normalizeOptions options

analyzeDependencies = ( context ) ->
  dependencies = analyze context.entries, {
    context.options...
    cwd: context.options.cwd
    platform: "node"
    conditions: [ "node" ]
    external: context.options.external
  }
  { context..., dependencies }

ingestDependencies = ( dependencies, options ) ->
  ingest dependencies, {
    options...
    cwd: options.cwd
  }

createPipeline = ( graph, components, index, map ) ->
  {
    graph, components, index, map
    moduleGraph: graph
    componentGraph: components
    treeIndex: index
    bundleMap: map
  }

applyFunctors = ( graph, options ) ->
  components = Quotient.apply graph
  index = Compiler.apply components, options
  map = Resolver.apply components, index, options.resolvers
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
