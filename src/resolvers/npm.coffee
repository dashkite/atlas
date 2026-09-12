import Path from "node:path"
import AtlasURL from "../url"

isDependency = ( target ) -> target?.source?.path?

make = ( config = {} ) ->
  match: ( target, context = {} ) ->
    unless isDependency( target ) || ( typeof target == "string" )
      return false
    path = if isDependency target then target.source.path else target
    path.includes "node_modules/"

  encode: ( target, context = {} ) ->
    unless @match target, context
      throw new Error "Target does not match NPM resolver"

    if isDependency target
      module = target.module
      unless module?.specifier?
        throw new Error "NPM resolver requires populated module metadata (specifier missing)"
        
      specifier = if module.version? && module.version != ""
        "#{ module.specifier }@#{ module.version }"
      else
        module.specifier
        
      rawSubpath = if module.path?
        Path.relative module.path, target.source.path
      else
        throw new Error "NPM resolver requires populated module metadata (path missing)"
        
      subpath = rawSubpath.replace( /^\.\//, "" ).replace /^\//, ""
    else
      targetPath = target
      marker = "node_modules/"
      index = targetPath.lastIndexOf marker
      if index == -1
        throw new Error "Cannot encode non-node_modules path with NPM resolver"
      remainder = targetPath.slice index + marker.length
      parts = remainder.split "/"
      if remainder.startsWith "@"
        specifier = parts.slice( 0, 2 ).join "/"
        subpath = parts.slice( 2 ).join "/"
      else
        specifier = parts[ 0 ]
        subpath = parts.slice( 1 ).join "/"

    AtlasURL.format
      type: "npm"
      specifier: specifier
      subpath: subpath

export default { make }
export { make }
