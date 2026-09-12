import JSZip from "jszip"
import Path from "node:path"

class BundleInspector
  constructor: ( @files ) ->
    # @files is an array of physical paths in the bundle

  @fromZip: ( zipBuffer ) ->
    zip = await JSZip.loadAsync zipBuffer
    files = Object.keys(zip.files).filter (f) -> !zip.files[f].dir
    new BundleInspector files

  @fromMap: ( bundleMap ) ->
    files = Array.from(bundleMap.keys())
    new BundleInspector files

  getFiles: ->
    @files

  findInstancesOf: ( packageName ) ->
    # Return all paths that look like they belong to packageName's root directory.
    # We look for "node_modules/packageName/..." and group them by the prefix.
    # For example, "node_modules/a/node_modules/pkg/index.js" -> prefix is "node_modules/a/node_modules/pkg"
    marker = "node_modules/#{packageName}"
    instances = new Set()
    
    for file in @files
      idx = file.lastIndexOf marker
      if idx != -1
        # The physical instance prefix
        prefix = file.slice 0, idx + marker.length
        instances.add prefix
        
    Array.from instances

  countInstancesOf: ( packageName ) ->
    @findInstancesOf(packageName).length

  hasFile: ( exactPath ) ->
    @files.includes exactPath

export default BundleInspector
