import assert from "./assert"
import {print, test, success} from "amen"
import * as _ from "@dashkite/joy"
import Fixtures from "./fixtures"

# system under test
import * as $ from "../src"

do ->

  print await test "atlas", [

    test "registy reference", await do (a = undefined, b = undefined) ->

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

    test "file reference", await do (a = undefined, b = undefined) ->

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

      test "exports path",  (foo = undefined) ->

        foo = _.assign (new $.RegistryReference),
          manifest:
            name: "foo"
            version: "1.0.0"
            exports: "./build/import/src/a.js"

        assert.equal 1, _.size foo.exports
        assert foo.exports["."]?
        assert.equal "./build/import/src/a.js", foo.exports["."]

      test "exports object", [

        test "...with .",  (foo = undefined) ->

          foo = _.assign (new $.RegistryReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              exports:
                ".": "./build/import/src/a.js"

          assert.equal 1, _.size foo.exports
          assert foo.exports["."]?
          assert.equal "./build/import/src/a.js", foo.exports["."]

        test "...with . in import condition",  (foo = undefined) ->

          foo = _.assign (new $.RegistryReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              exports:
                ".": import: "./build/import/src/a.js"

          assert.equal 1, _.size foo.exports
          assert foo.exports["."]?
          assert.equal "./build/import/src/a.js", foo.exports["."]

        test "...with subpath pattern",  (foo = undefined) ->

          foo = _.assign (new $.RegistryReference),
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

          assert.equal 5, _.size foo.exports
          assert foo.exports["."]?
          assert.equal "./build/import/src/a.js", foo.exports["."]
          assert.equal "./build/import/src/b.js", foo.exports["./b"]
          assert.equal "./build/import/src/c.js", foo.exports["./c"]
          assert.equal "./build/import/src/d/e.js", foo.exports["./d/e"]

        test "...with subpath pattern within import condition",
          (foo = undefined) ->

            foo = _.assign (new $.RegistryReference),
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

            assert.equal 5, _.size foo.exports
            assert foo.exports["."]?
            assert.equal "./build/import/src/a.js", foo.exports["."]
            assert.equal "./build/import/src/b.js", foo.exports["./b"]
            assert.equal "./build/import/src/c.js", foo.exports["./c"]
            assert.equal "./build/import/src/d/e.js", foo.exports["./d/e"]

        # TODO should we throw here, or just ignore?
        test "...throws if there's no import condition", (foo = undefined) ->

          foo = _.assign (new $.RegistryReference),
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

          assert.throws (-> foo.exports),
            message:
              "package [foo@1.0.0] uses exports conditions,
                but does not provide an 'import' condition"

      ]

    ]

    test "aliases (internal imports)", [

        test "...with #",  (foo = undefined) ->

          foo = _.assign (new $.RegistryReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              imports:
                "#a": "./build/import/src/a.js"

          assert.equal 1, _.size foo.aliases
          assert foo.aliases["#a"]?
          assert.equal "./build/import/src/a.js", foo.aliases["#a"]

        test "...with # in import condition",  (foo = undefined) ->

          foo = _.assign (new $.RegistryReference),
            manifest:
              name: "foo"
              version: "1.0.0"
              imports:
                "#a": import: "./build/import/src/a.js"

          assert.equal 1, _.size foo.aliases
          assert foo.aliases["#a"]?
          assert.equal "./build/import/src/a.js", foo.aliases["#a"]

        test "...with subpath pattern",  (foo = undefined) ->

          foo = _.assign (new $.RegistryReference),
            name: "foo"
            manifest:
              name: "foo"
              version: "1.0.0"
              imports:
                "#local": "./build/import/src/a.js"
                "#local/*": "./build/import/src/*.js"

            files: [
              "./build/import/src/a.js"
              "./build/import/src/b.js"
              "./build/import/src/c.js"
              "./build/import/src/d/e.js"
            ]

          assert.equal 5, _.size foo.aliases
          assert.equal "./build/import/src/a.js", foo.aliases["#local"]
          assert.equal "./build/import/src/b.js", foo.aliases["#local/b"]
          assert.equal "./build/import/src/c.js", foo.aliases["#local/c"]
          assert.equal "./build/import/src/d/e.js", foo.aliases["#local/d/e"]

        test "...with subpath pattern within import condition",
          (foo = undefined) ->

          foo = _.assign (new $.RegistryReference),
            name: "foo"
            manifest:
              name: "foo"
              version: "1.0.0"
              imports:
                "#local": "./build/import/src/a.js"
                "#local/*": import: "./build/import/src/*.js"

            files: [
              "./build/import/src/a.js"
              "./build/import/src/b.js"
              "./build/import/src/c.js"
              "./build/import/src/d/e.js"
            ]

          assert.equal 5, _.size foo.aliases
          assert.equal "./build/import/src/a.js", foo.aliases["#local"]
          assert.equal "./build/import/src/b.js", foo.aliases["#local/b"]
          assert.equal "./build/import/src/c.js", foo.aliases["#local/c"]
          assert.equal "./build/import/src/d/e.js", foo.aliases["#local/d/e"]

        # TODO should we throw here, or just ignore?
        test "...throws if there's no import condition", (foo = undefined) ->
          foo = _.assign (new $.RegistryReference),
            name: "foo"
            manifest:
              name: "foo"
              version: "1.0.0"
              imports:
                "#local": "./build/import/src/a.js"
                "#local/*": require: "./build/import/src/*.js"

            files: [
              "./build/import/src/a.js"
              "./build/import/src/b.js"
              "./build/import/src/c.js"
              "./build/import/src/d/e.js"
            ]

          assert.throws (-> foo.aliases),
            message:
              "package [foo@1.0.0] uses exports conditions,
                but does not provide an 'import' condition"

    ]

    test "import map", [

      test "scope", do (foo = undefined) ->

        foo = $.Scope.create "foo"
        foo.add Fixtures.d1
        foo.add Fixtures.e1

        [

          test "has", ->
            # different objects but same name/version
            assert foo.has Fixtures.e2
            # different objects, same name, but different version
            assert !(foo.has Fixtures.d2)

          test "canAdd", ->
            assert foo.canAdd Fixtures.c
            assert !(foo.canAdd Fixtures.d2)
            assert !(foo.canAdd Fixtures.e2)

        ]

      test "generation", do (json = undefined, map = undefined) ->

        json = Fixtures.a.map.toJSON $.jsdelivr
        map = JSON.parse json

        [

          test "produces a JSON file", ->
            assert _.isString json
            assert _.isObject JSON.parse json

          test "with the right imports", ->
            console.log map
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

          test "and the right scopes", (scope = undefined) ->
            assert map.scopes?

            assert (scope = map.scopes["https://cdn.jsdelivr.net/npm/c/"])?
            assert scope["d"]?
            assert scope["d/x"]?
            assert scope["d/y/z"]?

          test "and the right internal imports", (scope = undefined) ->
            assert (scope =
              map.scopes["https://cdn.jsdelivr.net/npm/b@1.0.0/"])?
            assert scope["#z"]?
            assert scope["#local/x"]?
            assert scope["#local/y/z"]?
      ]
    ]
  ]

  process.exit if success then 0 else 1
