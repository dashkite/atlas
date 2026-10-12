import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Path from "../../src/categories/path"

export default ->
  [
    test "creates root path", ->
      root = Path.root
      assert root.length == 0

    test "concatenates single path", ->
      path = Path.concat Path.root, "pkg-A"
      assert.equal path.length, 1
      assert.equal path[ 0 ], "pkg-A"

    test "concatenates nested paths", ->
      path = Path.concat Path.root, "pkg-A"
      path = Path.concat path, "pkg-B"
      assert.equal path.length, 2
      assert.equal path[ 0 ], "pkg-A"
      assert.equal path[ 1 ], "pkg-B"

    test "determines prefix relationships", ->
      paths =
        first: [ "pkg-A" ]
        second: [ "pkg-A", "pkg-B" ]
        third: [ "pkg-C" ]

      assert Path.isPrefix paths.first, paths.second
      assert !(Path.isPrefix paths.second, paths.first)
      assert !(Path.isPrefix paths.first, paths.third)
      assert Path.isPrefix Path.root, paths.first
  ]
