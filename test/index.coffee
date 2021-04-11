import assert from "./assert"
import {print, test, success} from "amen"
import * as _ from "@dashkite/joy"

# system under test
import * as x from "../src"

do ->

  print await test "import maps", [

    test "reference", [

      test "module reference", await do (a = undefined, b = undefined) ->

        a = await x.Reference.create "@dashkite/quark", "latest"
        b = await x.Reference.create "@dashkite/quark", "latest"

        [

          test "is a reference", ->
            assert.kind x.Reference, a

          test "has the expected name", ->
            assert.equal a.name, "@dashkite/quark"

          test "has the expected manifest", ->
            assert a.manifest?
            assert.equal a.manifest.name, "@dashkite/quark"

          test "has a version", ->
            assert a.version?

          test "has dependencies", ->
            assert a.dependencies?
            # TODO specialization for isType should rely on
            #      generic not currying
            assert.type Set, a.dependencies

          test "has files", ->
            assert a.files?
            assert _.isArray a.files

          test "same reference is strictly equal", ->
            assert a == b

        ]

      test "file reference", await do (a = undefined, b = undefined) ->

        a = await x.Reference.create "@dashkite/quark", "file:../quark"
        b = await x.Reference.create "@dashkite/quark", "file:../quark"

        [

          test "is a reference", ->
            assert.kind x.Reference, a

          test "has the expected name", ->
            assert.equal a.name, "@dashkite/quark"

          test "has the expected manifest", ->
            assert a.manifest?
            assert.equal a.manifest.name, "@dashkite/quark"

          test "has a version", ->
            assert a.version?

          test "has dependencies", ->
            assert a.dependencies?
            # TODO specialization for isType should rely on
            #      generic not currying
            assert.type Set, a.dependencies

          test "has files", ->
            assert a.files?
            assert _.isArray a.files

          test "same reference is strictly equal", ->
            assert a == b

        ]
    ]

    test "scope", await (a = undefined, b = undefined) ->

      a = await x.Reference.create "@dashkite/quark", "latest"
      b = await x.Reference.create "@dashkite/quark", "latest"

      [

        test "a reference has a scope", ->
          assert a.scope?

        test "that is a ModuleScope", ->
          assert.kind x.ModuleScope, a.scope

        test "that has dependencies", ->
          assert a.scope.dependencies?

        test "which are a set", ->
          assert.type Set, a.scope.dependencies

        test "consisting of references", ->
          assert.kind x.Reference, d for d from a.scope.dependencies

        test "same scope is strictly equal", ->
          assert a.scope == b.scope

    ]

    test "exports", [

      test "exports path",  (a = undefined) ->

        a = _.assign (new x.ModuleReference),
          manifest:
            name: "foo"
            version: "1.0.0"
            exports: "./build/import/src/a.js"


        assert.equal 1, _.size a.exports
        assert a.exports["."]?
        assert.equal "./build/import/src/a.js", a.exports["."]

      test "exports object", [

        test "...with .",  (a = undefined) ->

          a = _.assign (new x.ModuleReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              exports:
                ".": "./build/import/src/a.js"

          assert.equal 1, _.size a.exports
          assert a.exports["."]?
          assert.equal "./build/import/src/a.js", a.exports["."]

        test "...with . in import condition",  (a = undefined) ->

          a = _.assign (new x.ModuleReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              exports:
                ".": import: "./build/import/src/a.js"

          assert.equal 1, _.size a.exports
          assert a.exports["."]?
          assert.equal "./build/import/src/a.js", a.exports["."]

        test "...with subpath pattern",  (a = undefined) ->

          a = _.assign (new x.ModuleReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              exports:
                ".": "./build/import/src/a.js"
                "./*": "./build/import/src/*.js"
            files: [
              "./build/import/src/a.js"
              "./build/import/src/b.js"
              "./build/import/src/c.js"
              "./build/import/src/d/e.js"
            ]

          assert.equal 5, _.size a.exports
          assert a.exports["."]?
          assert.equal "./build/import/src/a.js", a.exports["."]
          assert.equal "./build/import/src/b.js", a.exports["./b"]
          assert.equal "./build/import/src/c.js", a.exports["./c"]
          assert.equal "./build/import/src/d/e.js", a.exports["./d/e"]

        test "...with subpath pattern within import condition",
          (a = undefined) ->

            a = _.assign (new x.ModuleReference),
              manifest:
                name: "foo"
                version: "1.0.0"
                exports:
                  ".": "./build/import/src/a.js"
                  "./*": import: "./build/import/src/*.js"
              files: [
                "./build/import/src/a.js"
                "./build/import/src/b.js"
                "./build/import/src/c.js"
                "./build/import/src/d/e.js"
              ]

            assert.equal 5, _.size a.exports
            assert a.exports["."]?
            assert.equal "./build/import/src/a.js", a.exports["."]
            assert.equal "./build/import/src/b.js", a.exports["./b"]
            assert.equal "./build/import/src/c.js", a.exports["./c"]
            assert.equal "./build/import/src/d/e.js", a.exports["./d/e"]

        test "...throws if there's no import condition", (a = undefined) ->
          a = _.assign (new x.ModuleReference),
            name: "foo"
            manifest:
              name: "foo"
              version: "1.0.0"
              exports:
                ".": "./build/import/src/a.js"
                "./*": require: "./build/import/src/*.js"
            files: [
              "./build/import/src/a.js"
              "./build/import/src/b.js"
              "./build/import/src/c.js"
              "./build/import/src/d/e.js"
            ]

          assert.throws (-> a.exports),
            message:
              "package foo@1.0.0 uses exports conditions,
                but does not provide an 'import' condition"

      ]


    ]

    test "import map", do (a = undefined) ->

      a = _.assign (new x.ModuleReference),
        name: "foo"
        manifest:
          name: "foo"
          version: "1.0.0"
          exports:
            ".": "./build/import/src/a.js"
            "./*": "./build/import/src/*.js"
        dependencies: new Set
        files: [
          "./build/import/src/a.js"
          "./build/import/src/b.js"
          "./build/import/src/c.js"
          "./build/import/src/d/e.js"
        ]

      [

        test "produces a JSON file", ->
          json = a.map.toJSON x.jsdelivr
          assert.equal true, _.isString json
          assert.equal true, _.isObject (map = JSON.parse json)
          # assert.equal true, map.imports?
          # assert.equal true, map.imports["@dashkite/katana"]?

    ]

  ]

  process.exit if success then 0 else 1
