import XRL from "./xrl"

unique = ( set, prefix ) ->
  1 ==
    set
      .values()
      .filter ( item ) -> item.startsWith prefix
      .toArray()
      .length

lca = ( input ) ->
  working = new Set input
  changed = true
  while changed
    scopes = working
    changed = false
    working = new Set()
    for scope from scopes
      parent = XRL.directory XRL.pop scope
      if ( parent != scope ) && !( unique scopes, parent )
        working.add parent
      else
        working.add scope
    changed = working.size != scopes.size
  scopes

export default lca
