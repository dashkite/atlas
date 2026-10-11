import JSZip from "jszip"

extractPrefix = ( file, marker ) ->
  markerIndex = file.lastIndexOf marker
  if markerIndex != -1
    file.slice 0, markerIndex + marker.length

class BundleInspector
  constructor: ( @files ) ->
    # @files is an array of physical paths in the bundle

  @fromZip: ( zipBuffer ) ->
    zip = await JSZip.loadAsync zipBuffer
    isFile = ( filePath ) -> !zip.files[ filePath ].dir
    files = ( Object.keys zip.files ).filter isFile
    new BundleInspector files

  @fromMap: ( bundleMap ) ->
    files = Array.from bundleMap.keys()
    new BundleInspector files

  getFiles: ->
    @files

  # Return all paths that look like they belong to packageName's root directory.
  # We look for "node_modules/packageName/..." and group them by the prefix.
  # For example, "node_modules/a/node_modules/pkg/index.js" ->
  # prefix is "node_modules/a/node_modules/pkg"
  findInstancesOf: ( packageName ) ->
    marker = "node_modules/#{packageName}"
    instances = new Set()
    for file in @files
      prefix = extractPrefix file, marker
      instances.add prefix if prefix
    Array.from instances

  countInstancesOf: ( packageName ) ->
    ( @findInstancesOf packageName ).length

  hasFile: ( exactPath ) ->
    @files.includes exactPath

export default BundleInspector