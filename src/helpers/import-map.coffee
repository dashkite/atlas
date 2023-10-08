import $Path from "node:path"
import * as Fn from "@dashkite/joy/function"

getParentScope = ( scope ) ->
  i = scope.lastIndexOf "/"
  if i >= 0
    result = scope[...i]
    switch result
      when "", "https:/" then null
      else result
  else null

isRootScope = ( scope ) -> !( getParentScope scope )?
    
hasSpecifierConflict = ({ scope, specifier, url }) ->
  if ( _url = scope[ specifier ])? then _url != url else false

hasScopeConflict = ({ scope, specifier, url }) ->
  if scope?
    hasSpecifierConflict {
      scope
      specifier
      url
    }
  else
    false

findMinimalScope = ({ map, scope, specifier, url }) ->
  loop
    parent = getParentScope scope
    _scope = if parent?
      map.scopes[ parent ]
    else
      map.imports
    if hasScopeConflict { scope: _scope, specifier, url }
      return map.scopes[ scope ] ?= {}
    if parent == null
      return map.imports
    scope = parent

normalizeSpecifier = ( specifier ) ->
  if specifier.endsWith ".js"
    specifier = specifier[...-3]
  if specifier.endsWith "/index"
    specifier = specifier[...-6]
  specifier

addMinimallyScopedMapping = do ({ mappings } = {}) ->
  ( map, dependency ) ->
    scope = findMinimalScope {
      map
      scope: dependency.import.scope.module.url
      specifier: dependency.import.specifier
      url: dependency.url
    }
    scope[ normalizeSpecifier dependency.import.specifier ] = dependency.url

addModuleScopedMapping = do ({ mappings } = {}) ->
  ( map, dependency ) ->
    relative = $Path.relative dependency.module.path, 
        dependency.source.path
    specifier = "#{ dependency.module.specifier }/#{ relative }"
    scope = findMinimalScope {
      map
      scope: dependency.import.scope.module.url
      specifier
      url: dependency.url
    }
    scope[ normalizeSpecifier specifier ] = dependency.url

addImportMapping = ( map, dependency ) ->
  map.imports[ normalizeSpecifier dependency.import.specifier ] =  dependency.url

isModuleSpecifier = ( specifier ) ->
  !( specifier.startsWith "." || specifier.startsWith "/" )

isRelative = ( dependency ) -> 
  dependency.url.startsWith "/"

_URL =
  join: ( a, b ) ->
    if a.startsWith "/"
      $Path.join ( $Path.dirname a ), b
    else
      ( new URL b, a ).toString()

ImportMap =

  make: ->
    imports: {}
    scopes: {}

  from: ({ imports, scopes }) -> { imports, scopes }

  add: Fn.tee ( map, dependency ) ->
    if dependency.import.specifier.startsWith "."
      specifier = _URL.join dependency.import.scope.url,
        dependency.import.specifier
      if specifier != dependency.url
        scope = map.scopes[ dependency.import.scope.url ] ?= {}
        scope[ specifier ] = dependency.url
    else
      map.imports[ dependency.import.specifier ] = dependency.url

export {
  ImportMap
}