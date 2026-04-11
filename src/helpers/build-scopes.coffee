buildScopes = ( pairs ) ->
  result = {}
  for { mapping, scopes } from pairs
    for scope from scopes
      result[ scope ] ?= {}
      result[ scope ][ mapping.specifier ] = mapping.target
  result

export default buildScopes
export { buildScopes }
