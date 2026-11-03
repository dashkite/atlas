import { pipe } from "@dashkite/joy"
import JSZip from "jszip"

extractPrefix = ( file, marker ) ->
  index = file.lastIndexOf marker
  if index != -1
    file.slice 0, index + marker.length

extractFiles = ( zip ) ->
  ( Object.keys zip.files ).filter ( path ) -> !zip.files[ path ].dir

class BundleInspector
  @make: ( files ) ->
    Object.assign ( new @ ),
      files: files

  @fromZip = pipe [
    JSZip.loadAsync
    extractFiles
    ( files ) => @make files
  ]

  @fromMap: ( map ) ->
    @make Array.from map.keys()

  getFiles: ->
    @files

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