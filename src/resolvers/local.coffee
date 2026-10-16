import AtlasURL from "../url"
import Path from "node:path"
import micromatch from "micromatch"
import { pathToFileURL } from "node:url"
import * as Codex from "@dashkite/url-codex"

SCOPED_TEMPLATE = "/{scope}/{versioned}/{path*}"
UNSCOPED_TEMPLATE = "/{versioned}/{path*}"
DEFAULT_PATTERNS = [ "../**/*", "packages/**/*" ]

normalizeConfig = ( config ) ->
  if !config.root?
    throw new Error "Local resolver requires 'root' in configuration"
  root: config.root
  workingDirectory: config.cwd ? process.cwd()
  patterns: config.patterns ? DEFAULT_PATTERNS

normalizeRelativePath = ( path, workingDirectory ) ->
  if Path.isAbsolute path
    Path.relative workingDirectory, path
  else
    path

matchPattern = ( path, patterns, workingDirectory ) ->
  if path.includes "node_modules"
    return false
  if patterns.length == 0
    return false
  path = normalizeRelativePath path, workingDirectory
  micromatch.isMatch path, patterns, { contains: true }

decodePathname = ( pathname ) ->
  if pathname.startsWith "/@"
    Codex.decode SCOPED_TEMPLATE, pathname
  else
    Codex.decode UNSCOPED_TEMPLATE, pathname

parseModule = ( scope, versioned ) ->
  parts = versioned.split "@"
  scope: scope
  name: parts[0]
  version: parts[1]

formatPath = ( path ) ->
  "/" + ( path ? [] ).join "/"

decodeUrl = ( url ) ->
  parsed = AtlasURL.parse url
  result = decodePathname parsed.pathname
  {
    resolver: parsed.resolver
    module: parseModule result.scope, result.versioned
    path: formatPath result.path
  }

resolvePath = ( root, descriptor ) ->
  path = Path.resolve root, descriptor.path.slice 1
  ( pathToFileURL path ).href

class LocalResolver
  @make: ( config = {} ) ->
    Object.assign ( new @ ), normalizeConfig config

  match: ( context ) ->
    matchPattern context.source, @patterns, @workingDirectory

  encode: ( descriptor ) ->
    AtlasURL.format descriptor

  decode: ( url ) ->
    decodeUrl url

  parse: ( url ) ->
    @decode url

  resolve: ( url ) ->
    resolvePath @root, @decode url

export default LocalResolver
export { LocalResolver }