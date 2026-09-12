import Path from "node:path"
import FS from "node:fs/promises"
import JSZip from "jszip"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import Quotient from "./functors/quotient"
import Compiler from "./functors/compiler"
import Resolver from "./functors/resolver"

stripVersion = ( str ) ->
  atIndex = str.lastIndexOf "@"
  if atIndex > 0
    str.slice 0, atIndex
  else
    str

findPackageManifest = ( filePath ) ->
  try
    realPath = await FS.realpath filePath
    directory = Path.dirname realPath
    while directory && directory != Path.dirname( directory )
      manifestPath = Path.join directory, "package.json"
      try
        await FS.access manifestPath
        return manifestPath
      catch
        directory = Path.dirname directory
  catch
    null

derivePackageBundleDirectory = ( filePath ) ->
  marker = "node_modules/"
  index = filePath.lastIndexOf marker
  return "" if index == -1

  prefix = filePath.slice 0, index + marker.length
  remainder = filePath.slice index + marker.length
  parts = remainder.split "/"

  packageName = if remainder.startsWith "@"
    parts.slice( 0, 2 ).join "/"
  else
    parts[ 0 ]

  Path.join prefix, packageName

resolveSourceDiskPath = ( root, sourceUrl, destination, moduleGraph ) ->
  # A strict O(1) lookup against the ingested ESBuild path map. No guessing!
  unless moduleGraph.sources.has sourceUrl
    throw new Error "Source URL not found in graph sources: #{sourceUrl}"

  fileUrl = moduleGraph.sources.get sourceUrl
  candidate = new URL(fileUrl).pathname

  try
    await FS.access candidate
    return candidate
  catch error
    throw new Error "Resolved source path is inaccessible on disk: #{candidate}. Reason: #{error.message}"

bundle = ( entries, options = {} ) ->
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

  # The Categorical Pipeline
  moduleGraph = await ingest deps, { options..., cwd, root: cwd }
  componentGraph = Quotient.apply moduleGraph
  treeIndex = Compiler.apply componentGraph, options
  bundleMap = Resolver.apply componentGraph, treeIndex

  diagDir = undefined
  console.log DEBUG: process.env.DEBUG
  if process.env.DEBUG
    diagDir = Path.join process.cwd(), ".atlas"
    try
      await FS.mkdir diagDir, recursive: true
      replacer = (key, value) ->
        if value instanceof Set then Array.from(value)
        else if value instanceof Map then Object.fromEntries(value)
        else value

      await FS.writeFile Path.join(diagDir, "module-graph.json"), JSON.stringify(moduleGraph, replacer, 2)
      await FS.writeFile Path.join(diagDir, "component-graph.json"), JSON.stringify(componentGraph, replacer, 2)
      await FS.writeFile Path.join(diagDir, "tree-index.json"), JSON.stringify(treeIndex, replacer, 2)
      await FS.writeFile Path.join(diagDir, "bundle-map.json"), JSON.stringify(bundleMap, replacer, 2)
    catch err
      console.warn "Atlas Diagnostics: Failed to emit state to .atlas -", err.message

  zip = new JSZip()
  visitedDestinations = new Set()
  visitedPackages = new Set()

  # Entry points
  for entry in entries
    relEntry = if Path.isAbsolute entry
      Path.relative cwd, entry
    else
      entry
    absEntry = Path.resolve cwd, relEntry
    unless visitedDestinations.has relEntry
      visitedDestinations.add relEntry
      content = await FS.readFile absEntry
      zip.file relEntry, content

  # Root package.json if present
  rootPkgJson = Path.resolve cwd, "package.json"
  try
    content = await FS.readFile rootPkgJson
    zip.file "package.json", content
    visitedDestinations.add "package.json"
  catch
    null

  for [ destination, sourceUrl ] from bundleMap
    diskPath = await resolveSourceDiskPath cwd, sourceUrl, destination, moduleGraph

    pkgBundleDir = derivePackageBundleDirectory destination
    if pkgBundleDir != "" && !visitedPackages.has( pkgBundleDir )
      visitedPackages.add pkgBundleDir
      manifestSource = await findPackageManifest diskPath
      if manifestSource?
        manifestDest = Path.join pkgBundleDir, "package.json"
        unless visitedDestinations.has manifestDest
          visitedDestinations.add manifestDest
          manifestContent = await FS.readFile manifestSource
          zip.file manifestDest, manifestContent

    unless visitedDestinations.has destination
      visitedDestinations.add destination
      fileContent = await FS.readFile diskPath
      zip.file destination, fileContent

  await zip.generateAsync
    type: "nodebuffer"
    compression: "DEFLATE"
    compressionOptions:
      level: 9

export default bundle
export { bundle }
