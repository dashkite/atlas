import { pipe } from "@dashkite/joy"
import JSZip from "jszip"

extractPrefix = ( file, marker ) ->
  index = file.lastIndexOf marker
  if index != -1
    file.slice 0, index + marker.length

extractZipFiles = ( zip ) ->
  ( Object.keys zip.files ).filter ( path ) -> !zip.files[ path ].dir

class BundleInspector
  @make: ( files ) ->
    Object.assign ( new @ ),
      files: files

  @fromZip: pipe [
    ( buffer ) -> JSZip.loadAsync buffer
    extractZipFiles
    ( files ) -> @make files
  ]

  @fromMap: pipe [
    ( map ) -> Array.from map.keys()
    ( files ) -> @make files
  ]

  getFiles: ->
    @files

  ###
  Return all paths that look like they belong to packageName's root directory.
  We look for "node_modules/packageName/..." and group them by the prefix.
  For example, "node_modules/a/node_modules/pkg/index.js" ->
  prefix is "node_modules/a/node_modules/pkg"
  ###
  findInstancesOf: pipe [
    ( name ) -> "node_modules/#{name}"
    ( marker ) -> @files.map ( file ) -> extractPrefix file, marker
    ( prefixes ) -> prefixes.filter Boolean
    ( prefixes ) -> Array.from new Set prefixes
  ]

  countInstancesOf: ( name ) ->
    ( @findInstancesOf name ).length

  hasFile: ( path ) ->
    @files.includes path

export default BundleInspector