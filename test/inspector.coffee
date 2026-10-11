import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import BundleInspector from "../src/helpers/inspector"

Inspector = BundleInspector

export default ->
  [
    test "finds instances of scoped and unscoped packages", ->
      files = [
        "node_modules/a/index.js",
        "node_modules/a/node_modules/@dashkite/joy/index.js",
        "node_modules/a/node_modules/@dashkite/joy/lib/util.js",
        "node_modules/@dashkite/joy/index.js",
        "node_modules/c/index.js"
      ]

      inspector = new Inspector files

      instances = inspector.findInstancesOf "@dashkite/joy"
      assert.equal instances.length, 2
      assert instances.includes "node_modules/a/node_modules/@dashkite/joy"
      assert instances.includes "node_modules/@dashkite/joy"

      instances = inspector.findInstancesOf "a"
      assert.equal instances.length, 1
      assert instances.includes "node_modules/a"
  ]