import AtlasURL from "../url"
import Path from "node:path"
import micromatch from "micromatch"
import { pathToFileURL } from "node:url"
import { decode as urlDecode } from "@dashkite/url-codex"

scopedTemplate = "/{scope}/{versioned}/{path*}"
unscopedTemplate = "/{versioned}/{path*}"
defaultPatterns = [ "../**/*", "packages/**/*" ]

normalizeConfig = ( config = {} ) ->
  if !config.root?
    throw new Error "Local resolver requires 'root' in configuration"
  root: config.root
  cwd: config.cwd ? process.cwd()
  patterns: config.patterns ? defaultPatterns

normalizeRelativePath = ( path, cwd ) ->
  if Path.isAbsolute path
    Path.relative cwd, path
  else
    path

matchPattern = ( path, patterns, cwd ) ->
  if path.includes "node_modules"
    return false
  if !patterns.length > 0
    return false
  relativePath = normalizeRelativePath path, cwd
  micromatch.isMatch relativePath, patterns, { contains: true }

decodePathname = ( pathname ) ->
  try
    match = urlDecode scopedTemplate, pathname
    if match.scope?.startsWith "@" then match else throw new Error
  catch
    urlDecode unscopedTemplate, pathname

parseModule = ( scope, versioned ) ->
  parts = versioned.split "@"
  scope: scope
  name: parts[0]
  version: parts[1]

formatPath = ( path ) ->
  "/" + ( path ? [] ).join "/"

decodeUrl = ( atlasUrl ) ->
  parsed = AtlasURL.parse atlasUrl
  result = decodePathname parsed.pathname
  {
    resolver: parsed.resolver
    module: parseModule result.scope, result.versioned
    path: formatPath result.path
  }

resolvePath = ( root, descriptor ) ->
  relativePath = descriptor.path
  relativePath = relativePath.slice 1 if relativePath.startsWith "/"
  absolutePath = Path.resolve root, relativePath
  ( pathToFileURL absolutePath ).href

make = ( config = {} ) ->
  { root, cwd, patterns } = normalizeConfig config
  match: ( context = {} ) -> matchPattern context.source, patterns, cwd
  encode: ( descriptor ) -> AtlasURL.format descriptor
  decode: ( atlasUrl ) -> decodeUrl atlasUrl
  parse: ( atlasUrl ) -> @decode atlasUrl
  resolve: ( atlasUrl ) -> resolvePath root, @decode atlasUrl

export default { make }
export { make }