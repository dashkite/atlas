import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"
import { decode } from "@dashkite/url-codex"

TEMPLATE =
  scoped: "/{scope}/{versioned}/{path*}"
  unscoped: "/{versioned}/{path*}"

decodePathname = ( pathname ) ->
  try
    match = decode TEMPLATE.scoped, pathname
    if match.scope.startsWith "@" then match else throw new Error
  catch
    decode TEMPLATE.unscoped, pathname

parseModule = ( { scope, versioned } ) ->
  [ name, version ] = versioned.split "@"
  { scope, name, version }

buildDescriptor = ( resolver, decoded ) ->
  {
    resolver
    module: parseModule decoded
    path: "/" + decoded.path.join "/"
  }

formatModuleName = ( { scope, name } ) ->
  if scope then "#{scope}/#{name}" else name

normalizeModulePath = ( path ) ->
  path.slice 1

class NodeResolver
  @make: ( config = {} ) ->
    Object.assign ( new @ ),
      root: config.root ? process.cwd()

  match: ( context ) ->
    context.source.includes "node_modules"

  encode: ( descriptor ) ->
    AtlasURL.format descriptor

  decode: ( url ) ->
    { resolver, pathname } = AtlasURL.parse url
    buildDescriptor resolver, decodePathname pathname

  parse: ( url ) ->
    @decode url

  resolve: ( url ) ->
    descriptor = @decode url
    name = formatModuleName descriptor.module
    path = normalizeModulePath descriptor.path
    # We resolve to node_modules in the root. If it's a monorepo, Node
    # resolution handles it. But for a physical URL, we just point to
    # node_modules/name/path
    resolved = Path.resolve @root, "node_modules", name, path
    ( pathToFileURL resolved ).href

export default NodeResolver
export { NodeResolver }