import Path from "node:path"
import FS from "node:fs/promises"
import JSZip from "jszip"
import { pipe } from "@dashkite/joy"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import Quotient from "./functors/quotient"
import Compiler from "./functors/compiler"
import Resolver from "./functors/resolver"
import nodePreset from "./presets/node"

ZIP_OPTIONS =
  type: "nodebuffer"
  compression: "DEFLATE"
  compressionOptions:
    level: 9

checkManifest = ( directory ) ->
  manifestPath = Path.join directory, "package.json"
  try
    await FS.access manifestPath
    manifestPath
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

findPackageManifest = ( filePath ) ->
  realPath = await FS.realpath filePath
  scanManifest Path.dirname realPath

extractPackageName = ( remainder ) ->
  parts = remainder.split "/"
  if remainder.startsWith "@"
    ( parts.slice 0, 2 ).join "/"
  else
    parts[ 0 ]

derivePackageBundleDirectory = ( filePath ) ->
  marker = "node_modules/"
  index = filePath.lastIndexOf marker
  if index == -1
    ""
  else
    Path.join ( filePath.slice 0, index + marker.length ),
      extractPackageName ( filePath.slice index + marker.length )

resolveSourceDiskPath = ( sourceUrl, moduleGraph ) ->
  fileUrl = moduleGraph.sources.get sourceUrl
  ( new URL fileUrl ).pathname

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
  filePath = Path.join directory, filename
  content = serializeDiagnostics data
  FS.writeFile filePath, content

deriveDiagnosticsDirectory = ( entries ) ->
  entryBasename = Path.basename entries[ 0 ], Path.extname entries[ 0 ]
  Path.join process.cwd(), ".atlas", "bundle", entryBasename

writePipelineDiagnostics = ( directory, pipeline ) ->
  { moduleGraph, componentGraph, treeIndex } = pipeline
  try
    await FS.mkdir directory, recursive: true
    await writeDiagnosticFile directory, "module-graph.json", moduleGraph
    await writeDiagnosticFile directory, "component-graph.json", componentGraph
    await writeDiagnosticFile directory, "tree-index.json", treeIndex
  catch error
    null
  return

writeBundleDiagnostics = ( directory, bundleMap ) ->
  try
    await writeDiagnosticFile directory, "bundle-map.json", bundleMap
  catch error
    null
  return

dumpDiagnostics = ( context ) ->
  if process.env.DEBUG
    directory = deriveDiagnosticsDirectory context.entries
    await writePipelineDiagnostics directory, context.pipeline
    await writeBundleDiagnostics directory, context.pipeline.bundleMap
  context

resolveEntryPaths = ( cwd, entry ) ->
  relative = if Path.isAbsolute entry
    Path.relative cwd, entry
  else
    entry
  absolute = Path.resolve cwd, relative
  { relative, absolute }

archiveEntry = ( context, entry ) ->
  { relative, absolute } = resolveEntryPaths context.cwd, entry
  await archiveFile context, relative, absolute
  return

archiveEntries = ( context, entries ) ->
  for entry in entries
    await archiveEntry context, entry
  return

resolveRootManifestPath = ( cwd ) ->
  Path.resolve cwd, "package.json"

readOptionalFile = ( filePath ) ->
  try
    FS.readFile filePath
  catch error
    if error.code != "ENOENT"
      throw error
    null

readRootManifest = ( cwd ) ->
  manifestPath = resolveRootManifestPath cwd
  readOptionalFile manifestPath

archiveRootManifest = ( context ) ->
  { zip, cwd, visitedDestinations } = context
  content = await readRootManifest cwd
  if content?
    zip.file "package.json", content
    visitedDestinations.add "package.json"
  return

archiveFile = ( context, destination, diskPath ) ->
  { zip, visitedDestinations } = context
  if !visitedDestinations.has destination
    visitedDestinations.add destination
    content = await FS.readFile diskPath
    zip.file destination, content
  return

archivePackageManifest = ( context, directory, diskPath ) ->
  manifestSource = await findPackageManifest diskPath
  if !manifestSource?
    throw new Error "Package manifest not found for #{ diskPath }"
  destination = Path.join directory, "package.json"
  await archiveFile context, destination, manifestSource
  return

archiveDependencyManifest = ( context, destination, diskPath ) ->
  { visitedPackages } = context
  directory = derivePackageBundleDirectory destination
  if directory != ""
    if !visitedPackages.has directory
      visitedPackages.add directory
      await archivePackageManifest context, directory, diskPath
  return

archiveBundleEntry = ( context, destination, sourceUrl ) ->
  diskPath = resolveSourceDiskPath sourceUrl, context.moduleGraph
  await archiveDependencyManifest context, destination, diskPath
  await archiveFile context, destination, diskPath
  return

archiveBundleMap = ( context, bundleMap ) ->
  for [ destination, sourceUrl ] from bundleMap
    await archiveBundleEntry context, destination, sourceUrl
  return

createArchiveContext = ( cwd, moduleGraph ) ->
  zip: JSZip()
  cwd: cwd
  moduleGraph: moduleGraph
  visitedDestinations: new Set()
  visitedPackages: new Set()

constructArchive = ( context ) ->
  archiveContext = createArchiveContext context.options.cwd,
    context.pipeline.moduleGraph
  await archiveEntries archiveContext, context.entries
  await archiveRootManifest archiveContext
  await archiveBundleMap archiveContext, context.pipeline.bundleMap
  archiveContext.zip.generateAsync ZIP_OPTIONS

validatePreconditions = ( entries, options ) ->
  if !entries?
    throw new Error "Entries argument is required"
  if ( typeof entries != "string" ) && !( Array.isArray entries )
    throw new Error "Entries must be a string or an Array"
  if ( typeof options != "object" ) || ( !options? )
    throw new Error "Options must be an object"

normalizeEntries = ( entries ) ->
  if typeof entries == "string"
    [ entries ]
  else
    entries

normalizeOptions = ( options ) ->
  cwd = options.cwd ? options.root ? process.cwd()
  external = [ "@aws-sdk/*", ( options.external ? [] )... ]
  resolvers = options.resolvers ? nodePreset
  { options..., cwd, external, resolvers }

createContext = ( entries, options = {} ) ->
  validatePreconditions entries, options
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
    root: options.cwd
  }

applyFunctors = ( moduleGraph, options ) ->
  componentGraph = Quotient.apply moduleGraph
  treeIndex = Compiler.apply componentGraph, options
  bundleMap = Resolver.apply componentGraph, treeIndex, options.resolvers
  { moduleGraph, componentGraph, treeIndex, bundleMap }

executeFunctors = ( context ) ->
  { dependencies, options } = context
  moduleGraph = await ingestDependencies dependencies, options
  pipeline = applyFunctors moduleGraph, options
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
