import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Path from "../../src/categories/path"

export default ->
  [
    test "creates root path", ->
      root = Path.root
      assert root.length == 0

    test "concatenates paths", ->
      root = Path.root
      p1 = Path.concat root, "pkg-A"
      p2 = Path.concat p1, "pkg-B"
      
      assert.equal p1.length, 1
      assert.equal p1[ 0 ], "pkg-A"

      assert.equal p2.length, 2
      assert.equal p2[ 0 ], "pkg-A"
      assert.equal p2[ 1 ], "pkg-B"

    test "determines prefix relationships", ->
      p1 = [ "pkg-A" ]
      p2 = [ "pkg-A", "pkg-B" ]
      p3 = [ "pkg-C" ]

      assert Path.isPrefix p1, p2
      assert !(Path.isPrefix p2, p1)
      assert !(Path.isPrefix p1, p3)
      assert Path.isPrefix Path.root, p1
  ]
