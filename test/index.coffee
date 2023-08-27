import assert from "@dashkite/assert"
import { test, success} from "@dashkite/amen"
import { print } from "@dashkite/amen-console"


import Path from "node:path"
import FS from "node:fs/promises"

# system under test
import * as $ from "../src"

do ->

  print await test "atlas", [

    test "generate", ->
      map = await $.generate [
        "../workspace-client/build/browser/src/index.js"
      ]

      assert map.imports?
      assert map.scopes?
      assert map.imports[ "@dashkite/joy/function" ]?
      assert map.scopes[ "/" ]?

  ]

  process.exit if success then 0 else 1
