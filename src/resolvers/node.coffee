import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"
import { decode as urlDecode } from "@dashkite/url-codex"

scopedTemplate = "/{scope}/{versioned}/{path*}"
unscopedTemplate = "/{versioned}/{path*}"

make = ( config = {} ) ->
  match: ( context = {} ) ->
    return false unless typeof context.source == "string"
    return context.source.includes "node_modules"

  encode: ( descriptor ) ->
    AtlasURL.format descriptor
    
  decode: ( atlasUrl ) ->
    parsed = AtlasURL.parse atlasUrl
    
    res = try
      match = urlDecode scopedTemplate, parsed.pathname
      if match.scope?.startsWith("@") then match else throw new Error()
    catch
      urlDecode unscopedTemplate, parsed.pathname
      
    parts = res.versioned.split("@")
    name = parts[0]
    version = parts[1]
    
    {
      resolver: parsed.resolver
      module:
        scope: res.scope
        name: name
        version: version
      path: "/" + (res.path ? []).join("/")
    }

  parse: ( atlasUrl ) ->
    @decode atlasUrl

  resolve: ( atlasUrl ) ->
    descriptor = @decode atlasUrl
    root = config.root ? config.cwd ? process.cwd()
    pkgName = if descriptor.module.scope then "#{descriptor.module.scope}/#{descriptor.module.name}" else descriptor.module.name
    relativePath = if descriptor.path != "" then descriptor.path else ""
    relativePath = relativePath.slice(1) if relativePath.startsWith("/")
    
    # We resolve to node_modules in the root. If it's a monorepo, Node resolution handles it.
    # But for a physical URL, we just point to node_modules/pkgName/relativePath
    absPath = Path.resolve root, "node_modules", pkgName, relativePath
    pathToFileURL(absPath).href

export default { make }
export { make }
