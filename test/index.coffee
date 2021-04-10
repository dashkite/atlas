import assert from "assert"
import {print, test, success} from "amen"
import { Reference, Resource, Scope, jsdelivr } from "../src"
import * as _ from "@dashkite/joy"

# TODO maybe split out the module stuff into a separate module?

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
          assert.equal true, _.isArray reference.files
          assert.equal true,
            _.includes "build/src/index.js", reference.files
          assert.equal true, _.includes "build/src/index.js",
            reference.glob "build/src/*.js"


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
          assert.equal true, _.isArray reference.files
          assert.equal true,
            _.includes "build/src/index.js", reference.files
          assert.equal true, _.includes "build/src/index.js",
            reference.glob "build/src/*.js"
          assert.equal true,
            _.includes "index", reference.capture "build/src/**.js"

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
          assert.equal true, _.isType Set, reference.scopes

    ]

    test "subpaths", [

      test
        description: "handle multiple exports"
        wait: 5000
        ->
          # TODO handle subpaths
          # TODO refine template interface
          # reference = await Reference.create "import-maps", "file:."
          # reference = await Reference.create "@dashkite/quark", "latest"
          # reference = await Reference.create "@dashkite/joy", "file:../joy"

    ]

    test "import map", [

      test
        description: "produces a JSON file"
        wait: 5000
        ->
          reference = await Reference.create "@dashkite/quark", "latest"
          json = reference.map.toJSON jsdelivr
          console.log json
          assert.equal true, _.isString json
          assert.equal true, _.isObject (map = JSON.parse json)
          assert.equal true, map.imports?
          assert.equal true, map.imports["@dashkite/katana"]?
    ]

  ]

  process.exit if success then 0 else 1
