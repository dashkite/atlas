Path =
  root: []

  concat: ( path, segment ) ->
    [ path..., segment ]

  isPrefix: ( prefix, path ) ->
    if prefix.length <= path.length
      prefix.every ( segment, index ) -> path[ index ] == segment
    else
      false

export default Path