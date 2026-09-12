import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import BundleInspector from "../src/helpers/inspector"

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
      
      inspector = new BundleInspector files
      
      joyInstances = inspector.findInstancesOf "@dashkite/joy"
      assert.equal joyInstances.length, 2
      assert joyInstances.includes "node_modules/a/node_modules/@dashkite/joy"
      assert joyInstances.includes "node_modules/@dashkite/joy"
      
      aInstances = inspector.findInstancesOf "a"
      assert.equal aInstances.length, 1
      assert aInstances.includes "node_modules/a"
  ]
