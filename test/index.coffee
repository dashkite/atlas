import assert from "@dashkite/assert"
import { test, success} from "@dashkite/amen"
import { print } from "@dashkite/amen-console"


import Path from "node:path"
import FS from "node:fs/promises"

# system under test
import * as $ from "../src"

do ->

  print await test "atlas", [

    test "registy reference", ->
      map = await $.generate [
        "../vedic-dolphin/.tempo/workspace-client\
          /build/browser/src/index.js"
      ]

      FS.writeFile "import-map.json", ( JSON.stringify map, null, 2 )

      # console.log files.filter ({ type }) -> type == "development"

  ]

  process.exit if success then 0 else 1
