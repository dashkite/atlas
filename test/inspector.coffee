import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import JSZip from "jszip"
import BundleInspector from "../src/helpers/inspector"

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
      inspector = BundleInspector.make FILES
      instances = inspector.findInstancesOf "@dashkite/joy"
      assert.equal instances.length, 2
      assert instances.includes "node_modules/a/node_modules/@dashkite/joy"
      assert instances.includes "node_modules/@dashkite/joy"

    test "finds instances of unscoped packages", ->
      inspector = BundleInspector.make FILES
      instances = inspector.findInstancesOf "a"
      assert.equal instances.length, 1
      assert instances.includes "node_modules/a"

    test "constructs inspector from a Map", ->
      map = new Map ( FILES.map ( file ) -> [ file, "" ])
      inspector = BundleInspector.fromMap map
      assert.equal ( inspector.countInstancesOf "@dashkite/joy" ), 2

    test "constructs inspector from a zip buffer", ->
      zip = new JSZip()
      for file in FILES
        zip.file file, "export default {}"
      buffer = await zip.generateAsync type: "nodebuffer"
      inspector = await BundleInspector.fromZip buffer
      assert.equal ( inspector.countInstancesOf "@dashkite/joy" ), 2
      assert inspector.hasFile "node_modules/a/index.js"
  ]