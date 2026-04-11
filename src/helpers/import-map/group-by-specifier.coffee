groupBySpecifier = ( mappings ) ->
  specifiers = {}
  for { mapping, scopes } in mappings
    { specifier, target } = mapping
    specifiers[ specifier ] ?= {}
    for scope from scopes
      specifiers[ specifier ][ scope ] = target
  specifiers

export default groupBySpecifier
export { groupBySpecifier }
