import AtlasURL from "../url"
import Path from "node:path"
import micromatch from "micromatch"
import { pathToFileURL } from "node:url"

DEFAULT_PATTERNS = [ "../**/*", "packages/**/*" ]

normalizeConfig = ( config ) ->
  if !config.root?
    throw new Error "Local resolver requires 'root' in configuration"
  root: config.root
  patterns: config.patterns ? DEFAULT_PATTERNS

normalizeRelativePath = ( path, directory ) ->
  if Path.isAbsolute path
    Path.relative directory, path
  else
    path

matchPattern = ( path, patterns, directory ) ->
  if path.includes "node_modules"
    return false
  if patterns.length == 0
    return false
  path = normalizeRelativePath path, directory
  micromatch.isMatch path, patterns, { contains: true }

resolvePath = ( root, descriptor ) ->
  path = Path.resolve root, descriptor.path.slice 1
  ( pathToFileURL path ).href

class LocalResolver
  @make: ( config = {} ) ->
    Object.assign ( new @ ), normalizeConfig config

  match: ( context ) ->
    matchPattern context.source, @patterns, ( context.cwd ? @root )

  encode: ( descriptor ) ->
    AtlasURL.encode descriptor

  decode: ( url ) ->
    AtlasURL.decode url

  parse: ( url ) ->
    @decode url

  resolve: ( url ) ->
    resolvePath @root, @decode url

export default LocalResolver
export { LocalResolver }