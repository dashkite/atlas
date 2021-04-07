import assert from "assert"
import {print, test, success} from "amen"
import { Reference } from "../src/reference"
import { Resource } from "../src/resource"
import { Scope } from "../src/scope"
import * as _ from "@dashkite/joy"

do ->

  print await test "import maps", [

    test "reference", [

      test
        description: "module reference"
        wait: 2000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          assert.equal true, _.isKind Reference, reference
          assert.equal "@dashkite/quark", reference.name
          assert.equal true, (manifest = await reference.manifest)?
          assert.equal manifest.name, reference.name
          assert.equal true, manifest.version?


      test
        description: "file reference"
        wait: 1000
        ->
          reference = await Reference.create "@dashkite/quark", "file:../quark"
          assert.equal true, _.isKind Reference, reference
          assert.equal "@dashkite/quark", reference.name
          assert.equal true, (manifest = await reference.manifest)?
          assert.equal manifest.name, reference.name
          assert.equal true, manifest.version?

      test
        description: "web reference"
        wait: 1000

      test
        description: "same description yields same object"
        wait: 2000
        ->
          a = await Reference.create "@dashkite/quark", "file:../quark"
          b = await Reference.create "@dashkite/quark", "file:../quark"
          assert.equal a, b

    ]

    test "resource", [

      test
        description: "module resource"
        wait: 2000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          resource = await Resource.create reference

      test
        description: "same reference yields same resource"
        wait: 2000
        ->
          a = await Reference.create "@dashkite/quark", "file:../quark"
          b = await Reference.create "@dashkite/quark", "file:../quark"
          assert.equal (await a.resource), (await b.resource)

      test
        description: "dependencies is a set of references"
        wait: 2000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          resource = await reference.resource
          dependencies = resource.dependencies
          assert.equal true, (_.isKind Set, dependencies)
          for d from dependencies
            assert.equal true, (_.isKind Reference, d)

    ]

    test "scope", [

      test
        description: "is a resource, set<reference> pair"
        wait: 2000
        ->
        reference = await Reference.create "@dashkite/quark", "latest"
        resource = await reference.resource
        scope = await resource.scope
        assert.equal true, (_.isKind Set, scope.dependencies)
        for d from scope.dependencies
          assert.equal true, (_.isKind Reference, d)
        assert.equal true, (_.isKind Resource, scope.resource)

      test
        description: "same resource yields same scope"
        wait: 2000
        ->
          a = await Reference.create "@dashkite/quark", "file:../quark"
          b = await Reference.create "@dashkite/quark", "file:../quark"
          assert.equal (await a.scope), (await b.scope)

      test
        description: "scopes for resource"
        wait: 2000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          scopes = await reference.scopes
          console.log scopes

    ]

    # test "dependency generation", [
    #
    #   test
    #     description: "dependencies"
    #     wait: 6000
    #     ->
    #       reference = await Reference.create "@dashkite/quark", "latest"
    #       dx = await reference.dependencies
    #       assert.equal true, _.isArray dx
    #       assert.equal true, _.isKind Reference, dx[0]
    #
    #   test
    #     description: "fullDependencies"
    #     wait: 6000
    #     ->
    #       reference = await Reference.create "@dashkite/quark", "latest"
    #       dx = await reference.scopes
    #       console.log dx
    #       assert.equal true, _.isArray dx
    #       assert.equal true, _.isKind Reference, dx[0]
    #
    # ]

    # test "scope generation", [
    #
    #   test
    #     description: "should work :)"
    #     wait: 6000
    #     ->
    #       result = await scopes "@dashkite/quark", "latest"
    #       console.log result
    #
    # ]


  ]

  process.exit if success then 0 else 1
