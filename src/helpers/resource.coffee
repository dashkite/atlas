import $Path from "node:path"
import { expand as _expand } from "@dashkite/polaris"
import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import * as Pred from "@dashkite/joy/predicate"
import { generic } from "@dashkite/joy/generic"

import { split, Directory } from "./file"

# Path.normalize does everything except the one thing I need it to do

Path = {
  
  $Path...
  
  trim: ( path ) -> if path.endsWith "/" then path[...-1] else path

}

getURL = ( entries, description ) ->
  { source, module } = description
  entry = entries.find ( entry ) -> 
    Directory.within entry, source.path  
  path = Path.relative module.path, source.path
  Path.trim do ->
    if entry?
      "/#{ path }"
    else if Directory.contains "node_modules", source.path
      if module.scope?
        "https://cdn.jsdelivr.net/npm\
          /@#{ module.scope }/#{ module.name }@#{ module.version }\
          /#{ path }"
      else
        "https://cdn.jsdelivr.net/npm\
          /#{ module.name }@#{ module.version }\
          /#{ path }"
    else
      if module.scope?
        "https://modules.dashkite.io/#{ source.hash }\
          /@#{ module.scope }/#{ module.name }@#{ module.version}\
          /#{ path }"
      else
        "https://modules.dashkite.io/#{ source.hash }\
          /#{ module.name }@#{ module.version}\
          /#{ path }"

decorateURL = ( entries, description ) ->
  description.url ?= await getURL entries, description

Resource =
  decorator: Fn.curry Fn.rtee ( entries, dependency ) ->
    Promise.all [
      decorateURL entries, dependency
      decorateURL entries, dependency.import.scope
    ]

export { Resource }