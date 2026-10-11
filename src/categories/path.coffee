Path =
  root: []

  concat: ( path, segment ) ->
    [ path..., segment ]

  isPrefix: ( prefix, path ) ->
    if prefix.length > path.length
      return false
    for segment, index in prefix
      if path[ index ] != segment
        return false
    true

export default Path