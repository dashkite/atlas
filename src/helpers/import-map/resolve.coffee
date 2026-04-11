resolve = ({ map, specifier, base }) ->

  scopes = 
    ( Object.keys map.scopes )
      .sort ( a, b ) -> b.length - a.length
  
  for scope in scopes
    if base.startsWith scope
      if map.scopes[ scope ][ specifier ]?
        return map.scopes[ scope ][ specifier ]

  if map.imports[ specifier ]?
    return map.imports[ specifier ]

  return undefined

export default resolve
export { resolve }
