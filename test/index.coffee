import assert from "./assert"
import {print, test, success} from "amen"
import * as _ from "@dashkite/joy"
import Fixtures from "./fixtures"

# system under test
import * as $ from "../src"

do ->

  print await test "package manager", [

    test "registy package", await do (a = undefined, b = undefined) ->

      a = await $.Reference.create "@dashkite/quark", "latest"
      b = await $.Reference.create "@dashkite/quark", "latest"
      c = await $.Reference.create "@dashkite/quark", "^1.1"

      [

        test "is a reference", ->
          assert.kind $.Reference, a

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

        test "resolving to the same version is strictly equal", ->
          assert a == b

        test "resolving to the different versions is strictly unequal", ->
          assert a != c

      ]

    test "file package", await do (a = undefined, b = undefined) ->

      a = await $.Reference.create "@dashkite/quark", "file:../quark"
      b = await $.Reference.create "@dashkite/quark", "file:../quark"

      [

        test "is a reference", ->
          assert.kind $.Reference, a

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

    test "exports", [

      test "exports path",  (a = undefined) ->

        a = _.assign (new $.ModuleReference),
          manifest:
            name: "foo"
            version: "1.0.0"
            exports: "./build/import/src/a.js"


        assert.equal 1, _.size a.exports
        assert a.exports["."]?
        assert.equal "./build/import/src/a.js", a.exports["."]

      test "exports object", [

        test "...with .",  (a = undefined) ->

          a = _.assign (new $.ModuleReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              exports:
                ".": "./build/import/src/a.js"

          assert.equal 1, _.size a.exports
          assert a.exports["."]?
          assert.equal "./build/import/src/a.js", a.exports["."]

        test "...with . in import condition",  (a = undefined) ->

          a = _.assign (new $.ModuleReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              exports:
                ".": import: "./build/import/src/a.js"

          assert.equal 1, _.size a.exports
          assert a.exports["."]?
          assert.equal "./build/import/src/a.js", a.exports["."]

        test "...with subpath pattern",  (a = undefined) ->

          a = _.assign (new $.ModuleReference),
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

            a = _.assign (new $.ModuleReference),
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
          a = _.assign (new $.ModuleReference),
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

    test "import map", [

      test "scope", await do (a = undefined, b = undefined) ->

        a = await $.Reference.create "@dashkite/quark", "latest"
        b = await $.Reference.create "@dashkite/quark", "latest"

        [

          test "a reference has a scope", ->
            assert a.scope?

          test "that is a ModuleScope", ->
            assert.kind $.ModuleScope, a.scope

          test "that has dependencies", ->
            assert a.scope.dependencies?

          test "which are a set", ->
            assert.type Set, a.scope.dependencies

          test "consisting of references", ->
            assert.kind $.Reference, d for d from a.scope.dependencies

          test "same scope is strictly equal", ->
            assert a.scope == b.scope

        ]

      test "generation", do (json = undefined, map = undefined) ->

        json = Fixtures.a.map.toJSON $.jsdelivr
        map = JSON.parse json

        [

          test "produces a JSON file", ->
            assert _.isString json
            assert _.isObject JSON.parse json

          test "with the right imports", ->
            assert map.imports?
            assert map.imports["a"]?
            assert map.imports["a/x"]?
            assert map.imports["a/y/z"]?
            assert map.imports["b"]?
            assert map.imports["b/x"]?
            assert map.imports["b/y/z"]?
            assert map.imports["c"]?
            assert map.imports["c/x"]?
            assert map.imports["c/y/z"]?
            assert map.imports["d"]?
            assert map.imports["d/x"]?
            assert map.imports["d/y/z"]?
            assert map.imports["e"]?
            assert map.imports["e/x"]?
            assert map.imports["e/y/z"]?
            assert.equal map.imports["e"],
              "https://cdn.jsdelivr.net/npm/e@1.1.0/build/import/src/z.js"

          test "and the right scopes", ->
            assert map.scopes?
            assert map.scopes["https://cdn.jsdelivr.net/npm/c"]?
            assert map.scopes["https://cdn.jsdelivr.net/npm/c"]["d"]?
            assert map.scopes["https://cdn.jsdelivr.net/npm/c"]["d/x"]?
            assert map.scopes["https://cdn.jsdelivr.net/npm/c"]["d/y/z"]?

      ]
    ]
  ]

  process.exit if success then 0 else 1
