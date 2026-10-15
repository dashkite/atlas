import JSZip from "jszip"

extractPrefix = ( file, marker ) ->
  index = file.lastIndexOf marker
  if index != -1
    file.slice 0, index + marker.length

class BundleInspector
  @make: ( files ) ->
    Object.assign ( new @ ),
      files: files

  @fromZip: ( buffer ) ->
    zip = await JSZip.loadAsync buffer
    isFile = ( path ) -> !zip.files[ path ].dir
    files = ( Object.keys zip.files ).filter isFile
    @make files

  @fromMap: ( map ) ->
    files = Array.from map.keys()
    @make files

  getFiles: ->
    @files

  # Return all paths that look like they belong to packageName's root directory.
  # We look for "node_modules/packageName/..." and group them by the prefix.
  # For example, "node_modules/a/node_modules/pkg/index.js" ->
  # prefix is "node_modules/a/node_modules/pkg"
  findInstancesOf: ( name ) ->
    marker = "node_modules/#{name}"
    instances = new Set()
    for file in @files
      prefix = extractPrefix file, marker
      instances.add prefix if prefix
    Array.from instances

  countInstancesOf: ( name ) ->
    ( @findInstancesOf name ).length

  hasFile: ( path ) ->
    @files.includes path

export default BundleInspector