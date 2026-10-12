import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import Inspector from "../src/helpers/inspector"

FILES = [
  "node_modules/a/index.js"
  "node_modules/a/node_modules/@dashkite/joy/index.js"
  "node_modules/a/node_modules/@dashkite/joy/lib/util.js"
  "node_modules/@dashkite/joy/index.js"
  "node_modules/c/index.js"
]

export default ->
  [
    test "finds instances of scoped packages", ->
      inspector = Inspector.make FILES
      instances = Inspector.findInstancesOf inspector, "@dashkite/joy"
      assert.equal instances.length, 2
      assert instances.includes "node_modules/a/node_modules/@dashkite/joy"
      assert instances.includes "node_modules/@dashkite/joy"

    test "finds instances of unscoped packages", ->
      inspector = Inspector.make FILES
      instances = Inspector.findInstancesOf inspector, "a"
      assert.equal instances.length, 1
      assert instances.includes "node_modules/a"
  ]