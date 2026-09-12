import Path from "node:path"
import micromatch from "micromatch"
import AtlasURL from "../url"

isDependency = ( target ) -> target?.source?.path?

make = ( config = {} ) ->
  patterns = config.patterns ? [ "../**/*", "packages/**/*" ]
  
  match: ( target, context = {} ) ->
    unless isDependency( target ) || ( typeof target == "string" )
      return false

    path = if isDependency target then target.source.path else target
    return false if path.includes "node_modules"

    return false unless patterns.length > 0
    micromatch.isMatch path, patterns, { contains: true }

  encode: ( target, context = {} ) ->
    unless @match target, context
      throw new Error "Target does not match Local resolver"

    if isDependency target
      sourcePath = target.source.path
      module = target.module
      
      unless module?.specifier?
        throw new Error "Local resolver requires fully populated module metadata"
        
      specifier = if module?.version? && module.version != ""
        "#{ module.specifier }@#{ module.version }"
      else
        module.specifier
        
      rawSubpath = if module?.path?
        Path.relative module.path, sourcePath
      else
        throw new Error "Local resolver requires fully populated module metadata"
        
      subpath = rawSubpath.replace( /^\.\//, "" ).replace /^\//, ""
    else
      throw new Error "Local resolver encode requires full dependency object"

    AtlasURL.format
      type: "local"
      specifier: specifier
      subpath: subpath

export default { make }
export { make }
