import Ajv from "ajv"
import { pipe } from "@dashkite/joy"
import AtlasURL from "../url"
import Path from "node:path"
import { pathToFileURL } from "node:url"

ajv = new Ajv()

validateConfiguration = ajv.compile
  type: "object"
  properties:
    root:
      type: "string"
      minLength: 1

formatName = ({ scope, name }) ->
  if scope then "#{scope}/#{name}" else name

normalizePath = ( path ) ->
  path.slice 1

# We resolve to node_modules in the root. If it's a monorepo, Node
# resolution handles it. But for a physical URL, we just point to
# node_modules/name/path
resolvePath = ( root, { module, path }) ->
  Path.resolve root, "node_modules",
    ( formatName module ),
    ( normalizePath path )

toFileURL = ( path ) ->
  ( pathToFileURL path ).href

class NodeResolver
  @make: ( configuration = {}) ->
    if validateConfiguration configuration
      Object.assign ( new @ ),
        root: configuration.root ? process.cwd()
    else
      throw new Error "Invalid Node resolver configuration"

  match: ( context ) ->
    context.source.includes "node_modules"

  encode: ( descriptor ) ->
    AtlasURL.encode descriptor

  decode: ( url ) ->
    AtlasURL.decode url

  resolve: pipe [
    ( url ) -> @decode url
    ( descriptor ) -> resolvePath @root, descriptor
    toFileURL
  ]

export default NodeResolver
export { NodeResolver }