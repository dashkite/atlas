groupByMapping = ( scopes ) ->
  index = {}
  for scope, mappings of scopes
    for specifier, target of mappings
      index[ specifier ] ?= {}
      index[ specifier ][ target ] ?= new Set()
      index[ specifier ][ target ].add scope
  
  results = []
  for specifier, targets of index
    for target, scopes of targets
      results.push { mapping: { specifier, target }, scopes }
  
  results.sort ( a, b ) -> b.scopes.size - a.scopes.size

export default groupByMapping
export { groupByMapping }
