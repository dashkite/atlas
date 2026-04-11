compact = ( map ) ->
  for scope, mappings of map.scopes
    if ( Object.keys mappings ).length == 0
      delete map.scopes[ scope ]
  map

export default compact
