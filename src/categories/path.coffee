Path =
  root: []

  concat: ( path, segment ) ->
    [ path..., segment ]

  isPrefix: ( prefix, path ) ->
    return false if prefix.length > path.length
    for segment, i in prefix
      return false if path[ i ] != segment
    true

export default Path
