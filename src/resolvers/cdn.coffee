import Path from "node:path"
import AtlasURL from "../url"
import { encode } from "@dashkite/url-codex"

isDependency = ( target ) -> target?.source?.path?

unpkg = "https://unpkg.com/:package@:version/*subpath"
esm = "https://esm.sh/:package@:version/*subpath"

make = ( config = {} ) ->
  template = config.template
  unless template?
    throw new Error "CDN resolver requires a template configuration"

  match: ( target, context = {} ) ->
    unless isDependency( target ) || ( typeof target == "string" )
      return false
    path = if isDependency target then target.source.path else target
    path.includes "node_modules/"

  encode: ( target, context = {} ) ->
    unless @match target, context
      throw new Error "Target does not match CDN resolver"

    if isDependency target
      module = target.module
      unless module?.specifier?
        throw new Error "CDN resolver requires populated module metadata"
        
      specifier = module.specifier
      version = module.version ? ""
      
      rawSubpath = if module.path?
        Path.relative module.path, target.source.path
      else
        throw new Error "CDN resolver requires populated module metadata"
        
      subpath = rawSubpath.replace( /^\.\//, "" ).replace /^\//, ""
      subpathArray = subpath.split("/").filter Boolean
      
      urlParams =
        package: specifier
        version: version
        subpath: subpathArray
      
      interpolatedUrl = encode template, urlParams
      
      AtlasURL.format
        type: "cdn"
        subpath: interpolatedUrl
    else
      throw new Error "CDN resolver encode requires full dependency object"

export default { make, unpkg, esm }
export { make, unpkg, esm }
