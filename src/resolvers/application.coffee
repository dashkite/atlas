import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"

make = ( config = {} ) ->
  match: ( context = {} ) ->
    return false unless typeof context.source == "string"
    return false if context.source.includes "node_modules"
    return false if context.source.startsWith ".."
    true

  encode: ( descriptor ) ->
    AtlasURL.format descriptor
    
  decode: ( atlasUrl ) ->
    parsed = AtlasURL.parse atlasUrl
    {
      resolver: parsed.resolver
      path: parsed.pathname
    }

  parse: ( atlasUrl ) ->
    @decode atlasUrl

  resolve: ( atlasUrl ) ->
    descriptor = @decode atlasUrl
    root = config.root ? config.cwd ? process.cwd()
    relativePath = if descriptor.path != "" then descriptor.path else ""
    relativePath = relativePath.slice(1) if relativePath.startsWith("/")
    absPath = Path.resolve root, relativePath
    pathToFileURL(absPath).href

export default { make }
export { make }
