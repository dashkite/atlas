import Path from "node:path"
import FS from "node:fs/promises"
import JSZip from "jszip"
import { pipe } from "@dashkite/joy"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import quotient from "./functors/quotient"
import compile from "./functors/compiler"
import resolve from "./functors/resolver"
import preset from "./presets/node"

ZIP_OPTIONS =
  type: "nodebuffer"
  compression: "DEFLATE"
  compressionOptions:
    level: 9

Manifest =
  check: ( directory ) ->
    path = Path.join directory, "package.json"
    try
      await FS.access path
      path
    catch error
      if error.code != "ENOENT"
        throw error
      null

  scan: ( directory ) ->
    current = directory
    while current && ( current != Path.dirname current )
      manifest = await Manifest.check current
      if manifest?
        return manifest
      current = Path.dirname current
    null

  find: ( path ) ->
    path = await FS.realpath path
    Manifest.scan Path.dirname path

  read: ( directory ) ->
    path = Path.resolve directory, "package.json"
    try
      await FS.readFile path
    catch error
      if error.code != "ENOENT"
        throw error
      null

Package =
  name: ( remainder ) ->
    parts = remainder.split "/"
    if remainder.startsWith "@"
      ( parts.slice 0, 2 ).join "/"
    else
      parts[ 0 ]

  directory: ( path ) ->
    marker = "node_modules/"
    index = path.lastIndexOf marker
    if index == -1
      ""
    else
      prefix = index + marker.length
      Path.join ( path.slice 0, prefix ),
        Package.name path.slice prefix

Source =
  path: ( source, graph ) ->
    url = graph.sources.get source
    ( new URL url ).pathname

Entry =
  resolve: ( cwd, source, entry ) ->
    absolute = Path.resolve source, entry
    relative = Path.relative cwd, absolute
    { relative, absolute }

  normalize: ( entries ) ->
    if !entries?
      throw new Error "Entries argument is required"
    [ entries ].flat()

Diagnostics =
  serialize: ( value ) ->
    replacer = ( key, item ) ->
      if item instanceof Set
        Array.from item
      else if item instanceof Map
        Object.fromEntries item
      else
        item
    JSON.stringify value, replacer, 2

  write: ( directory, filename, data ) ->
    path = Path.join directory, filename
    content = Diagnostics.serialize data
    FS.writeFile path, content

  directory: ( entries ) ->
    basename = Path.basename entries[ 0 ], Path.extname entries[ 0 ]
    Path.join process.cwd(), ".atlas", "bundle", basename

  pipeline: ( directory, pipeline ) ->
    { graph, components, index } = pipeline
    await FS.mkdir directory, recursive: true
    await Diagnostics.write directory, "module-graph.json", graph
    await Diagnostics.write directory, "component-graph.json", components
    await Diagnostics.write directory, "tree-index.json", index
    return

  bundle: ( directory, map ) ->
    await Diagnostics.write directory, "bundle-map.json", map
    return

  dump: ( context ) ->
    if process.env.DEBUG
      try
        directory = Diagnostics.directory context.entries
        await Diagnostics.pipeline directory, context.pipeline
        await Diagnostics.bundle directory, context.pipeline.map
      catch error
        console.warn error
    context

class BundleArchive
  @make: ( options, graph ) ->
    Object.assign ( new @ ),
      zip: JSZip()
      cwd: options.cwd
      source: options.source
      graph: graph
      destinations: new Set()
      packages: new Set()

  @construct: ( context ) ->
    archive = BundleArchive.make context.options, context.pipeline.graph
    await archive.addEntries context.entries
    await archive.addManifest()
    await archive.addMap context.pipeline.map
    archive.generate()

  addFile: ( destination, path ) ->
    if !@destinations.has destination
      @destinations.add destination
      content = await FS.readFile path
      @zip.file destination, content
    return

  addEntry: ( entry ) ->
    { relative, absolute } = Entry.resolve @cwd, @source, entry
    await @addFile relative, absolute
    return

  addEntries: ( entries ) ->
    for entry in entries
      await @addEntry entry
    return

  addManifest: ->
    content = await Manifest.read @cwd
    if content?
      @zip.file "package.json", content
      @destinations.add "package.json"
    return

  addPackage: ( directory, path ) ->
    manifest = await Manifest.find path
    if !manifest?
      throw new Error "Package manifest not found for #{ path }"
    destination = Path.join directory, "package.json"
    await @addFile destination, manifest
    return

  ensurePackage: ( destination, path ) ->
    directory = Package.directory destination
    if directory != ""
      if !@packages.has directory
        @packages.add directory
        await @addPackage directory, path
    return

  addDependency: ( destination, source ) ->
    path = Source.path source, @graph
    await @ensurePackage destination, path
    await @addFile destination, path
    return

  addMap: ( map ) ->
    for [ destination, source ] from map
      await @addDependency destination, source
    return

  generate: ->
    @zip.generateAsync ZIP_OPTIONS

Options =
  normalize: ( options ) ->
    cwd = options.cwd ? process.cwd()
    source = Path.resolve cwd, ( options.source ? "." )
    external = [ "@aws-sdk/*", ( options.external ? [])... ]
    resolvers = options.resolvers ? preset
    { options..., cwd, source, external, resolvers }

Context =
  create: ( entries, options = {}) ->
    entries: Entry.normalize entries
    options: Options.normalize options

Dependencies =
  analyze: ( context ) ->
    dependencies = analyze context.entries, {
      context.options...
      platform: "node"
      conditions: [ "node" ]
    }
    { context..., dependencies }

  ingest: ( dependencies, options ) ->
    ingest dependencies, options

Functors =
  apply: ( graph, options ) ->
    components = quotient graph
    index = compile components, options
    map = resolve components, index, options.resolvers
    { graph, components, index, map }

  execute: ( context ) ->
    { dependencies, options } = context
    graph = await Dependencies.ingest dependencies, options
    pipeline = Functors.apply graph, options
    { context..., pipeline }

bundle = pipe [
  Context.create
  Dependencies.analyze
  Functors.execute
  Diagnostics.dump
  BundleArchive.construct
]

export default bundle
export { bundle }
