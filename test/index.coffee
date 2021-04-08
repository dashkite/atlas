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
        wait: 5000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          assert.equal true, _.isKind Reference, reference
          assert.equal "@dashkite/quark", reference.name
          assert.equal true, (manifest = reference.manifest)?
          assert.equal manifest.name, reference.name
          assert.equal true, manifest.version?
          assert.equal true, reference.dependencies?
          assert.equal (_.size reference.dependencies),
            (_.size reference.manifest.dependencies)


      test
        description: "file reference"
        wait: 5000
        ->
          reference = await Reference.create "@dashkite/quark", "file:../quark"
          assert.equal true, _.isKind Reference, reference
          assert.equal "@dashkite/quark", reference.name
          assert.equal true, (manifest = reference.manifest)?
          assert.equal manifest.name, reference.name
          assert.equal true, manifest.version?
          assert.equal true, reference.dependencies?
          assert.equal (_.size reference.dependencies),
            (_.size reference.manifest.dependencies)

      test
        description: "web reference"
        wait: 5000

      test
        description: "same description yields same object"
        wait: 5000
        ->
          a = await Reference.create "@dashkite/quark", "file:../quark"
          b = await Reference.create "@dashkite/quark", "file:../quark"
          assert.equal a, b

    ]

    test "resource", [

      test
        description: "module resource"
        wait: 5000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          resource = reference.resource
          assert.equal true, _.isKind Resource, resource

      test
        description: "same reference yields same resource"
        wait: 5000
        ->
          a = await Reference.create "@dashkite/quark", "file:../quark"
          b = await Reference.create "@dashkite/quark", "file:../quark"
          assert.equal a.resource, b.resource

      test
        description: "dependencies is a set of references"
        wait: 5000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          dependencies = reference.resource.dependencies
          assert.equal true, (_.isKind Set, dependencies)
          for d from dependencies
            assert.equal true, (_.isKind Reference, d)

    ]

    test "scope", [

      test
        description: "is a resource, set<reference> pair"
        wait: 5000
        ->
        reference = await Reference.create "@dashkite/quark", "latest"
        scope = reference.resource.scope
        assert.equal true, (_.isKind Set, scope.dependencies)
        for d from scope.dependencies
          assert.equal true, (_.isKind Reference, d)
        assert.equal true, (_.isKind Resource, scope.resource)

      test
        description: "same resource yields same scope"
        wait: 5000
        ->
          a = await Reference.create "@dashkite/quark", "file:../quark"
          b = await Reference.create "@dashkite/quark", "file:../quark"
          assert.equal a.scope, b.scope

      test
        description: "scopes for resource"
        wait: 5000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          console.log reference.map.toJSON()

    ]

  ]

  process.exit if success then 0 else 1
