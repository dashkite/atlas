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
      firstPath = Path.concat root, "pkg-A"
      secondPath = Path.concat firstPath, "pkg-B"

      assert.equal firstPath.length, 1
      assert.equal firstPath[ 0 ], "pkg-A"

      assert.equal secondPath.length, 2
      assert.equal secondPath[ 0 ], "pkg-A"
      assert.equal secondPath[ 1 ], "pkg-B"

    test "determines prefix relationships", ->
      firstPath = [ "pkg-A" ]
      secondPath = [ "pkg-A", "pkg-B" ]
      thirdPath = [ "pkg-C" ]

      assert Path.isPrefix firstPath, secondPath
      assert !(Path.isPrefix secondPath, firstPath)
      assert !(Path.isPrefix firstPath, thirdPath)
      assert Path.isPrefix Path.root, firstPath
  ]
