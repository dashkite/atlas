import Path from "node:path"
import { expand as _expand } from "@dashkite/polaris"
import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import * as Pred from "@dashkite/joy/predicate"
import { generic } from "@dashkite/joy/generic"

import { split, Directory } from "./file"

# Paths = 

#   contains: ( paths, path ) ->
#     Type.isDefined do ->
#       paths
#         .map ( path ) -> Path.dirname path
#         .find ( directory ) -> Directory.within directory, path


expand = Fn.curry ( template, context ) -> 
  _expand template, context

isLocal = ({ local }) -> local

isDevelopment = ({ module }) -> module.hash?

isProduction = ({ module }) ->
  Directory.contains "node_modules", module.path

hasScope = ({ module }) -> module.scope?

getURL = generic
  name: "getURL"
  description: "Obtain a URL from a module description"
  default: ( value ) ->
    throw new Error "Unable to generate URL for #{ value?.path }"

generic getURL,
  isLocal,
  ({ path }) ->
    expand "/${ path }",
      path: Path.relative "build/browser/src", path

generic getURL,
  isDevelopment,
  expand "https://modules.dashkite.io/\
    ${ module.hash }/${ module.name }@${ module.version}/${ path }"

generic getURL,
  ( Pred.all [ hasScope, isDevelopment ]),
  expand "https://modules.dashkite.io/\
    ${ module.hash }/@${ module.scope }/${ module.name }@${ module.version}/${ path }"

generic getURL, 
  isProduction, 
  expand "https://cdn.jsdelivr.net/npm/\
    ${ module.name }@${ module.version}/${ path }"

generic getURL,
  ( Pred.all [ hasScope, isProduction ]),
  expand "https://cdn.jsdelivr.net/npm/\
    @${ module.scope }/${ module.name }@${ module.version}/${ path }"

Resource =
  decorator: Fn.tee ( dependency ) ->
    dependency.url = await getURL dependency
    dependency.import.scope.module.url = await getURL dependency.import.scope


export { Resource }