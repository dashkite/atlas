import assert from "@dashkite/assert"
import { test, success} from "@dashkite/amen"
import { print } from "@dashkite/amen-console"

import Path from "node:path"

# system under test
import * as $ from "../src"

do ->

  print await test "atlas", [

    test "registy reference", ->
      map = await $.generate [
        "../vedic-dolphin/.tempo/workspace-client\
          /build/browser/src/index.js"
      ]

      # console.log JSON.stringify map, null, 2

      # console.log files.filter ({ type }) -> type == "development"

  ]

  process.exit if success then 0 else 1
