import assert from "assert"
import {print, test, success} from "amen"
import { Resource } from "../src/resource"
import * as _ from "@dashkite/joy"

do ->

  print await test "import maps", [

    test "resource", [

      test
        description: "module resource"
        wait: 1000
        ->
          resource = await Resource.create "@dashkite/quark", "latest"
          assert.equal true, _.isKind Resource, resource
          assert.equal "@dashkite/quark", resource.name
          assert.equal true, resource.manifest?
          assert.equal resource.version, resource.manifest.version


      test
        description: "file resource"
        wait: 1000
        ->
          resource = await Resource.create "@dashkite/quark", "file:../quark"
          assert.equal true, _.isKind Resource, resource
          assert.equal "@dashkite/quark", resource.name
          assert.equal true, resource.manifest?
          assert.equal resource.version, resource.manifest.version

    ]
  ]

  process.exit if success then 0 else 1
