import groupByMapping from "./group-by-mapping"

buildRoot = ( scopes ) ->
  groups = groupByMapping scopes
  
  # Identify mappings that are in the root scope
  rootMappings = groups.filter ( { scopes: groupScopes } ) -> groupScopes.has "/"
  otherMappings = groups.filter ( { scopes: groupScopes } ) -> !groupScopes.has "/"

  # Sort non-root mappings by frequency (descending)
  otherMappings.sort ( a, b ) ->
    b.scopes.size - a.scopes.size
  
  imports = {}
  
  # 1. Always promote root mappings first
  for { mapping } in rootMappings
    imports[ mapping.specifier ] = mapping.target
    
  # 2. Promote other mappings by frequency if no conflict
  for { mapping } in otherMappings
    unless imports[ mapping.specifier ]?
      imports[ mapping.specifier ] = mapping.target
  
  # Rebuild scopes without the promoted mappings
  resultScopes = {}
  for scope, mappings of scopes
    for specifier, target of mappings
      if imports[ specifier ] != target
        resultScopes[ scope ] ?= {}
        resultScopes[ scope ][ specifier ] = target
        
  { imports, scopes: resultScopes }

export default buildRoot
export { buildRoot }
