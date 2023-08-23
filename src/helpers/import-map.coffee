import * as Fn from "@dashkite/joy/function"

getParentURL = ( url ) ->
  i = url.lastIndexOf "/"
  if i > 0 then url[...i] else ""

getParentScope = ( scope ) ->
  i = scope.lastIndexOf "/"
  if i >= 0
    result = scope[...i]
    switch result
      when "" then "/"
      when "https:/" then scope
      else result
  else scope

isRootScope = ( scope ) ->
  switch getParentScope scope
    when scope, "/" then true
    else false
    
hasSpecifierConflict = ( mappings, dependency ) ->
  if ( url = mappings[ dependency.import.specifier ])? then url != dependency.url
  else false

hasScopeConflict = ( map, scope, dependency ) ->
  if map.scopes[ scope ]?
    hasSpecifierConflict map.scopes[ scope ], dependency
  else
    false

findMinimalScope = ( map, dependency ) ->
  current = dependency.import.scope.module.url
  loop
    parent = getParentScope current
    break if hasScopeConflict map, parent, dependency
    current = parent
    break if isRootScope current
  current

addScopedMapping = do ({ mappings } = {}) ->
  ( map, dependency ) ->
    scope = findMinimalScope map, dependency
    ( mappings = map.scopes[ scope ] ?= {} )
    mappings[ dependency.import.specifier ] = dependency.url

addImportMapping = ( map, dependency ) ->
  map.imports[ dependency.import.specifier ] = dependency.url

isModuleSpecifier = ( specifier ) ->
  !( specifier.startsWith "." || specifier.startsWith "/" )

isLocalSpecifier = ( specifier ) -> specifier.startsWith "."

ImportMap =

  make: ->
    imports: {}
    scopes: {}

  from: ({ imports, scopes }) -> { imports, scopes }

  add: ( map, dependency ) ->
    if isModuleSpecifier dependency.import.specifier
      if hasSpecifierConflict map.imports, dependency
          addScopedMapping map, dependency
      else
        addImportMapping map, dependency
    else if ! isLocalSpecifier dependency.import.specifier
      addScopedMapping map, dependency
    map

export {
  ImportMap
}