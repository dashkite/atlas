import assert from "assert"
import {print, test, success} from "amen"
import { Resource } from "../src/resource"
import { dependencies } from "../src/dependencies"
import * as _ from "@dashkite/joy"

do ->

  print await test "import maps", [

    test "resource", [

      test
        description: "module resource"
        wait: 2000
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

      test
        description: "web resource"
        wait: 1000

    ]

    test "dependency generation", [

      test
        description: "should work :)"
        wait: 6000
        ->
          dx = await dependencies "@dashkite/quark", "latest"
          assert.equal true, _.isObject dx
          # assert.equal true, _.all _.isArray, _.values dx
          assert.equal true, _.isArray (_.values dx)[0]
          assert.equal true, _.isKind Resource, (_.values dx)[0][0]


    ]
  ]

  process.exit if success then 0 else 1
