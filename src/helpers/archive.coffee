import FS from "node:fs/promises"
import Path from "node:path"
import JSZip from "jszip"
import Manifest from "./manifest"

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
      name = Package.name path.slice prefix
      Path.join ( path.slice 0, prefix ), name

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
    absolute = Path.resolve @source, entry
    relative = Path.relative @cwd, absolute
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
    if ( directory != "" ) && !( @packages.has directory )
      @packages.add directory
      await @addPackage directory, path
    return

  addDependency: ( destination, source ) ->
    url = @graph.sources.get source
    path = ( new URL url ).pathname
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

export default BundleArchive
export { BundleArchive }
