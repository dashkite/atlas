import JSZip from "jszip"

extractPrefix = ( file, marker ) ->
  index = file.lastIndexOf marker
  if index != -1
    file.slice 0, index + marker.length

Inspector =
  make: ( files = [] ) ->
    files: files

  fromZip: ( buffer ) ->
    zip = await JSZip.loadAsync buffer
    isFile = ( path ) -> !zip.files[ path ].dir
    files = ( Object.keys zip.files ).filter isFile
    Inspector.make files

  fromMap: ( map ) ->
    files = Array.from map.keys()
    Inspector.make files

  getFiles: ( inspector ) ->
    inspector.files

  # Return all paths that look like they belong to packageName's root directory.
  # We look for "node_modules/packageName/..." and group them by the prefix.
  # For example, "node_modules/a/node_modules/pkg/index.js" ->
  # prefix is "node_modules/a/node_modules/pkg"
  findInstancesOf: ( inspector, name ) ->
    marker = "node_modules/#{name}"
    instances = new Set()
    for file in inspector.files
      prefix = extractPrefix file, marker
      instances.add prefix if prefix
    Array.from instances

  countInstancesOf: ( inspector, name ) ->
    ( Inspector.findInstancesOf inspector, name ).length

  hasFile: ( inspector, path ) ->
    inspector.files.includes path

export default Inspector