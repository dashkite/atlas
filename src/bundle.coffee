import Path from "node:path"
import FS from "node:fs/promises"
import JSZip from "jszip"
import Ajv from "ajv"
import { pipe } from "@dashkite/joy"
import { isSet, isMap, isString, isArray } from "@dashkite/joy/type"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import quotient from "./functors/quotient"
import compile from "./functors/compiler"
import resolve from "./functors/resolver"
import preset from "./presets/node"

Manifest =
  check: ( directory ) ->
    path = Path.join directory, "package.json"
    try
      await FS.access path
      path
    catch error
      if error.code == "ENOENT"
        null
      else
        throw error

  scan: ( directory ) ->
    current = directory
    manifest = null
    while current && ( current != Path.dirname current ) && ( !manifest? )
      manifest = await Manifest.check current
      if !manifest?
        current = Path.dirname current
    manifest

  find: ( path ) ->
    path = await FS.realpath path
    Manifest.scan Path.dirname path

  read: ( directory ) ->
    path = Path.resolve directory, "package.json"
    try
      await FS.readFile path
    catch error
      if error.code == "ENOENT"
        null
      else
        throw error

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
  isValid: ( entries ) ->
    if isString entries
      entries.length > 0
    else if isArray entries
      ( entries.length > 0 ) && ( entries.every ( entry ) ->
        ( isString entry ) && ( entry.length > 0 )
      )
    else
      false

  resolve: ( cwd, source, entry ) ->
    absolute = Path.resolve source, entry
    relative = Path.relative cwd, absolute
    { relative, absolute }

  normalize: ( entries ) ->
    if Entry.isValid entries
      [ entries ].flat()
    else
      throw new Error "Entries argument is required"

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

Diagnostics =
  replacer: ( key, item ) ->
    if isSet item
      Array.from item
    else if isMap item
      Object.fromEntries item
    else
      item

  serialize: ( value ) ->
    JSON.stringify value, Diagnostics.replacer, 2

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
    await archive.populate context
    archive.generate()

  populate: ( context ) ->
    await @addEntries context.entries
    await @addManifest()
    await @addMap context.pipeline.map
    return

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
    if manifest?
      destination = Path.join directory, "package.json"
      await @addFile destination, manifest
    else
      throw new Error "Package manifest not found for #{ path }"
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
    @zip.generateAsync
      type: "nodebuffer"
      compression: "DEFLATE"
      compressionOptions:
        level: 9

Options =
  normalize: ( options = {}) ->
    if validateOptions options
      cwd = Path.resolve ( options.cwd ? process.cwd() )
      resolvers = options.resolvers ? preset
      external = [ "@aws-sdk/*", ( options.external ? [])... ]
      source =
        if options.source?
          Path.resolve cwd, options.source
        else
          cwd
      { options..., cwd, source, resolvers, external }
    else
      throw new Error "Invalid bundle options"

Dependencies =
  analyze: ( context ) ->
    dependencies = analyze context.entries, {
      context.options...
      platform: "node"
      conditions: [ "node" ]
    }
    { context..., dependencies }

Context =
  create: ( entries, options = {}) ->
    entries: Entry.normalize entries
    options: Options.normalize options

Context.prepare = pipe [
  Context.create
  Dependencies.analyze
]

Functors =
  apply: ( graph, options ) ->
    components = quotient graph
    index = compile components, options
    map = resolve components, index, options.resolvers
    { graph, components, index, map }

  execute: ( context ) ->
    graph = await ingest context.dependencies, context.options
    pipeline = Functors.apply graph, context.options
    { context..., pipeline }

bundle = pipe [
  Context.prepare
  Functors.execute
  Diagnostics.dump
  BundleArchive.construct
]

export default bundle
export { bundle }
