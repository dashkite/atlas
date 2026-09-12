import Path from "node:path"
import AtlasURL from "../url"

isDependency = ( target ) -> target?.source?.path?

make = ( config = {} ) ->
  match: ( target, context = {} ) ->
    unless isDependency( target ) || ( typeof target == "string" )
      return false
      
    path = if isDependency target then target.source.path else target

    return false if path.includes "node_modules"
    return false if path.startsWith ".."
    true

  encode: ( target, context = {} ) ->
    unless @match target, context
      throw new Error "Target does not match Application resolver"

    rawPath = if isDependency target then target.source.path else target
      
    root = context.root ? context.cwd ? process.cwd()

    subpath = if Path.isAbsolute rawPath
      Path.relative root, rawPath
    else
      rawPath.replace( /^\.\//, "" ).replace( /^\//, "" )

    AtlasURL.format
      type: "application"
      subpath: subpath

export default { make }
export { make }
