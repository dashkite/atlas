import $Path from "node:path"
import { expand as _expand } from "@dashkite/polaris"
import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import * as Pred from "@dashkite/joy/predicate"
import { generic } from "@dashkite/joy/generic"
import * as DRN from "@dashkite/drn-sky"

import { split, Directory } from "./file"

# Path.normalize does everything except the one thing I need it to do

Path = {
  
  $Path...
  
  trim: ( path ) -> if path.endsWith "/" then path[...-1] else path

}

getProductionModuleURL = ({ scope, name, version }) ->
  Path.trim do ->
    if scope?
      "https://cdn.jsdelivr.net/npm/\
        @#{ scope }/#{ name }@#{ version }"
    else
      "https://cdn.jsdelivr.net/npm/\
        #{ name }@#{ version }"

getDevelopmentModuleURL = ( origin, { scope, name }) ->
  Path.trim do ->
    if scope?
      "#{ origin }/@#{ scope }/#{ name }"
    else
      "#{ origin }/#{ name }"

isRoot = ( entry, description ) ->
  ( Path.normalize description.import.scope.source.path ) == 
    ( Path.normalize entry )

decorateWithURLs = ( entries, description ) ->
  { source, module } = description
  origin = await DRN.resolve "drn:origin/modules/dashkite/com"
  entry = entries.find ( entry ) -> 
    Directory.within ( Path.dirname entry ), source.path  
  path = Path.relative module.path, source.path
  if entry?
    module.url = "/"
    if description.import?
      description.root = isRoot entry, description
      if description.root
        description.import.specifier = "/#{ Path.normalize description.import.specifier }"
    path = Path.relative ( Path.dirname entry ), source.path
    description.url = "/#{ path }"
  else if Directory.contains "node_modules", source.path
    module.url = getProductionModuleURL module
    description.url = Path.trim "#{ module.url }/#{ path }"
  else
    module.url = getDevelopmentModuleURL origin, module
    description.url = Path.trim "#{ module.url }\
      /#{ source.hash }\
      /#{ path }"

Resource =
  decorator: Fn.curry Fn.rtee ( entries, dependency ) ->
    Promise.all [
      decorateWithURLs entries, dependency
      decorateWithURLs entries, dependency.import.scope
    ]

export { Resource }