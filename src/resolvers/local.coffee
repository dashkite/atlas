import AtlasURL from "../url"
import Path from "node:path"
import micromatch from "micromatch"
import { pathToFileURL } from "node:url"

DEFAULT_PATTERNS = [ "../**/*", "packages/**/*" ]

normalize = ( config ) ->
  if !config.root?
    throw new Error "Local resolver requires 'root' in configuration"
  root: config.root
  patterns: config.patterns ? DEFAULT_PATTERNS

relative = ( path, directory ) ->
  if Path.isAbsolute path
    Path.relative directory, path
  else
    path

class LocalResolver
  @make: ( config = {}) ->
    Object.assign ( new @ ), normalize config

  match: ( context ) ->
    { source } = context
    if source.includes "node_modules"
      return false
    if @patterns.length == 0
      return false
    path = relative source, ( context.cwd ? @root )
    micromatch.isMatch path, @patterns, { contains: true }

  encode: ( descriptor ) ->
    AtlasURL.encode descriptor

  decode: ( url ) ->
    AtlasURL.decode url

  parse: ( url ) ->
    @decode url

  resolve: ( url ) ->
    { path } = @decode url
    resolved = Path.resolve @root, path.slice 1
    ( pathToFileURL resolved ).href

export default LocalResolver
export { LocalResolver }