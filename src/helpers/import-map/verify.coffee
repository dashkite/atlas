import resolve from "./resolve"

verify = ({ map, specifier, target, scopes }) ->
  for scope, t of scopes
    base = if scope == "$" then "/" else scope
    return false if resolve({ map, specifier, base }) != t
  true

export default verify
