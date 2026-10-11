import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"
import { decode as urlDecode } from "@dashkite/url-codex"

template =
  scoped: "/{scope}/{versioned}/{path*}"
  unscoped: "/{versioned}/{path*}"

make = ( config = {} ) ->
  match: ( context ) ->
    context.source.includes "node_modules"

  encode: ( descriptor ) ->
    AtlasURL.format descriptor

  decode: ( url ) ->
    parsed = AtlasURL.parse url

    decoded = try
      match = urlDecode template.scoped, parsed.pathname
      if match.scope?.startsWith "@" then match else throw new Error
    catch
      urlDecode template.unscoped, parsed.pathname

    parts = decoded.versioned.split "@"
    name = parts[ 0 ]
    version = parts[ 1 ]

    {
      resolver: parsed.resolver
      module:
        scope: decoded.scope
        name: name
        version: version
      path: "/" + ( decoded.path ? [] ).join "/"
    }

  parse: ( url ) ->
    @decode url

  resolve: ( url ) ->
    descriptor = @decode url
    root = config.root ? config.cwd ? process.cwd()
    name = if descriptor.module.scope
      "#{descriptor.module.scope}/#{descriptor.module.name}"
    else
      descriptor.module.name
    path = if descriptor.path != "" then descriptor.path else ""
    path = path.slice 1 if path.startsWith "/"

    # We resolve to node_modules in the root. If it's a monorepo, Node resolution handles it.
    # But for a physical URL, we just point to node_modules/name/path
    path = Path.resolve root, "node_modules", name, path
    ( pathToFileURL path ).href

export default { make }
export { make }