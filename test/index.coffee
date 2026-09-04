import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import groupByMapping from "../src/helpers/import-map/group-by-mapping"
import groupBySpecifier from "../src/helpers/import-map/group-by-specifier"
import Map from "../src/helpers/import-map"
import resolve from "../src/helpers/import-map/resolve"
import Generators from "../src/generators"
import Local from "../src/generators/local"
import Atlas from "../src/index"

do ->
  print await test "groupByMapping", [
    test "basic grouping", ->

      normalize = ( actual ) ->
        actual.map ({ mapping, scopes }) ->
          { mapping, scopes: [ scopes... ]}

      scopes =
        a: x: "v1"
        b: x: "v2"
        c:
          x: "v2"
          y: "v1"

      expected = [
        { mapping: { specifier: "x", target: "v2" }, scopes: [ "b", "c" ]}
        { mapping: { specifier: "x", target: "v1" }, scopes: [ "a" ]}
        { mapping: { specifier: "y", target: "v1" }, scopes: [ "c" ]}
      ]

      assert.deepEqual expected,
        normalize groupByMapping scopes

  ]

  print await test "groupBySpecifier", [
    test "aggregation by specifier", ->
      mappings = [
        { mapping: { specifier: "x", target: "v1" }, scopes: new Set [ "/a/" ]}
        { mapping: { specifier: "x", target: "v2" }, scopes: new Set [ "/b/" ]}
        { mapping: { specifier: "y", target: "v1" }, scopes: new Set [ "/c/" ]}
      ]
      
      expected = 
        "x":
          "/a/": "v1"
          "/b/": "v2"
        "y":
          "/c/": "v1"
          
      assert.deepEqual expected, groupBySpecifier mappings
  ]

  print await test "Map.optimize", [
    test "full integration", ->
      map = 
        imports:
          "z": "v1"
        scopes:
          "/a/b/c/": "x": "v1"
          "/a/b/d/": "x": "v1"
          "/other/": "x": "v2"

      optimized = Map.optimize map

      expected =
        imports:
          x: "v1"
          z: "v1"
        scopes:
          "/other/":
            x: "v2"

      assert.deepEqual expected, optimized

    test "shadowing conflict", ->
      map = 
        imports:
          "x": "v1"
        scopes:
          "/a/1/": "x": "v1"
          "/a/2/": "x": "v2"
          "/a/3/": "x": "v2"

      optimized = Map.optimize map
      
      assert.equal "v1",
        resolve { map: optimized, specifier: "x", base: "/a/1/" }
      assert.equal "v2",
        resolve { map: optimized, specifier: "x", base: "/a/2/" }
    test "scoped package subpath alias isolation", ->
      map =
        imports: {}
        scopes:
          "/node_modules/@scope/pkg-a@1.0.0/src/":
            "#helpers": "/node_modules/@scope/pkg-a@1.0.0/src/helpers.js"
          "/node_modules/@scope/pkg-b@1.0.0/src/":
            "#helpers": "/node_modules/@scope/pkg-b@1.0.0/src/helpers.js"

      optimized = Map.optimize map

      assert.deepEqual {
        imports: {}
        scopes:
          "/node_modules/@scope/pkg-a@1.0.0/":
            "#helpers": "/node_modules/@scope/pkg-a@1.0.0/src/helpers.js"
          "/node_modules/@scope/pkg-b@1.0.0/":
            "#helpers": "/node_modules/@scope/pkg-b@1.0.0/src/helpers.js"
      }, optimized
  ]

  print await test "resolve", [
    test "nested scopes", ->
      map =
        imports:
          "x": "global"
        scopes:
          "/a/":
            "x": "v1"
          "/a/b/":
            "x": "v2"
      
      assert.equal "v2", 
        resolve { map, specifier: "x", base: "/a/b/c.js" }
      assert.equal "v1", 
        resolve { map, specifier: "x", base: "/a/c.js" }
      assert.equal "global", 
        resolve { map, specifier: "x", base: "/other.js" }

    test "shadowing", ->
      map =
        imports:
          "x": "global"
        scopes:
          "/a/":
            "y": "v1"
      
      assert.equal "global",
        resolve { map, specifier: "x", base: "/a/b.js" }
  ]

  print await test "Local Generator", [
    test "root importing a package", ->
      generator = Local.make root: "."
      dep1 =
        source:
          path: "node_modules/pkg-a/index.js"
        module:
          name: "pkg-a"
          specifier: "pkg-a"
          version: "1.0.0"
          path: "node_modules/pkg-a"
        import:
          scope:
            source:
              path: "src/index.js"
            module:
              name: "my-project"
              specifier: "my-project"
              version: "1.0.0"
              path: "."
          specifier: "pkg-a"

      mapping1 = await generator.apply dep1
      assert.deepEqual {
        scope: "/"
        specifier: "pkg-a"
        target: "/node_modules/pkg-a@1.0.0/index.js"
      }, mapping1

    test "root importing a local file", ->
      generator = Local.make root: "."
      depLocal =
        source:
          path: "src/helper.js"
        module:
          name: "my-project"
          specifier: "my-project"
          version: "1.0.0"
          path: "."
        import:
          scope:
            source:
              path: "src/index.js"
            module:
              name: "my-project"
              specifier: "my-project"
              version: "1.0.0"
              path: "."
          specifier: "./helper.js"

      mappingLocal = await generator.apply depLocal
      assert.deepEqual {
        scope: "/"
        specifier: "./helper.js"
        target: "/src/helper.js"
      }, mappingLocal

    test "nested package import", ->
      generator = Local.make root: "."

      depNested =
        source:
          path: "node_modules/pkg-a/node_modules/pkg-b/index.js"
        module:
          name: "pkg-b"
          specifier: "pkg-b"
          version: "1.0.0"
          path: "node_modules/pkg-a/node_modules/pkg-b"
        import:
          scope:
            source:
              path: "node_modules/pkg-a/index.js"
            module:
              name: "pkg-a"
              specifier: "pkg-a"
              version: "1.0.0"
              path: "node_modules/pkg-a"
          specifier: "pkg-b"

      mappingNested = await generator.apply depNested
      assert.deepEqual {
        scope: "/node_modules/pkg-a@1.0.0/"
        specifier: "pkg-b"
        target: "/node_modules/pkg-a@1.0.0/node_modules/pkg-b@1.0.0/index.js"
      }, mappingNested

    test "multi-version package resolution with Map.add", ->
      Generators.clear()
      Generators.register Local.make root: "."

      depA =
        source:
          path: "node_modules/pkg-a/index.js"
        module:
          name: "pkg-a"
          specifier: "pkg-a"
          version: "1.0.0"
          path: "node_modules/pkg-a"
        import:
          scope:
            source:
              path: "src/index.js"
            module:
              name: "my-project"
              specifier: "my-project"
              version: "1.0.0"
              path: "."
          specifier: "pkg-a"

      depB =
        source:
          path: "node_modules/pkg-b/index.js"
        module:
          name: "pkg-b"
          specifier: "pkg-b"
          version: "1.0.0"
          path: "node_modules/pkg-b"
        import:
          scope:
            source:
              path: "src/index.js"
            module:
              name: "my-project"
              specifier: "my-project"
              version: "1.0.0"
              path: "."
          specifier: "pkg-b"

      depX1 =
        source:
          path: "node_modules/pkg-a/node_modules/dep-x/index.js"
        module:
          name: "dep-x"
          specifier: "dep-x"
          version: "1.0.0"
          path: "node_modules/pkg-a/node_modules/dep-x"
        import:
          scope:
            source:
              path: "node_modules/pkg-a/index.js"
            module:
              name: "pkg-a"
              specifier: "pkg-a"
              version: "1.0.0"
              path: "node_modules/pkg-a"
          specifier: "dep-x"

      depX2 =
        source:
          path: "node_modules/pkg-b/node_modules/dep-x/index.js"
        module:
          name: "dep-x"
          specifier: "dep-x"
          version: "2.0.0"
          path: "node_modules/pkg-b/node_modules/dep-x"
        import:
          scope:
            source:
              path: "node_modules/pkg-b/index.js"
            module:
              name: "pkg-b"
              specifier: "pkg-b"
              version: "1.0.0"
              path: "node_modules/pkg-b"
          specifier: "dep-x"

      map = Map.make()
      map = await Map.add map, depA
      map = await Map.add map, depB
      map = await Map.add map, depX1
      map = await Map.add map, depX2

      assert.equal "/node_modules/pkg-a@1.0.0/index.js",
        resolve { map, specifier: "pkg-a", base: "/src/index.js" }
      assert.equal "/node_modules/pkg-b@1.0.0/index.js",
        resolve { map, specifier: "pkg-b", base: "/src/index.js" }
      assert.equal "/node_modules/pkg-a@1.0.0/node_modules/dep-x@1.0.0/index.js",
        resolve { map, specifier: "dep-x", base: "/node_modules/pkg-a@1.0.0/index.js" }
      assert.equal "/node_modules/pkg-b@1.0.0/node_modules/dep-x@2.0.0/index.js",
        resolve { map, specifier: "dep-x", base: "/node_modules/pkg-b@1.0.0/index.js" }

    test "nested package internal subdirectory relative import", ->
      generator = Local.make root: "."
      depNestedRel =
        source:
          path: "node_modules/pkg-b/node_modules/dep-x/src/helper.js"
        module:
          name: "dep-x"
          specifier: "dep-x"
          version: "2.0.0"
          path: "node_modules/pkg-b/node_modules/dep-x"
        import:
          scope:
            source:
              path: "node_modules/pkg-b/node_modules/dep-x/src/index.js"
            module:
              name: "dep-x"
              specifier: "dep-x"
              version: "2.0.0"
              path: "node_modules/pkg-b/node_modules/dep-x"
            import:
              scope:
                source:
                  path: "node_modules/pkg-b/index.js"
                module:
                  name: "pkg-b"
                  specifier: "pkg-b"
                  version: "1.0.0"
                  path: "node_modules/pkg-b"
          specifier: "./helper.js"

      mappingNestedRel = await generator.apply depNestedRel
      assert.deepEqual {
        scope: "/node_modules/pkg-b@1.0.0/node_modules/dep-x@2.0.0/src/"
        specifier: "./helper.js"
        target: "/node_modules/pkg-b@1.0.0/node_modules/dep-x@2.0.0/src/helper.js"
      }, mappingNestedRel

    test "scoped namespace package (@scope/pkg)", ->
      generator = Local.make root: "."
      depScoped =
        source:
          path: "node_modules/@dashkite/dolores/build/node/src/secrets.js"
        module:
          name: "dolores"
          scope: "dashkite"
          specifier: "@dashkite/dolores"
          version: "1.0.0"
          path: "node_modules/@dashkite/dolores"
        import:
          scope:
            source:
              path: "src/index.js"
            module:
              name: "my-app"
              specifier: "my-app"
              version: "1.0.0"
              path: "."
          specifier: "@dashkite/dolores/secrets"

      mappingScoped = await generator.apply depScoped
      assert.deepEqual {
        scope: "/"
        specifier: "@dashkite/dolores/secrets"
        target: "/node_modules/@dashkite/dolores@1.0.0/build/node/src/secrets.js"
      }, mappingScoped

    test "subpath alias import (#helpers) inside package", ->
      generator = Local.make root: "."
      depAlias =
        source:
          path: "node_modules/pkg-a/src/helpers/index.js"
        module:
          name: "pkg-a"
          specifier: "pkg-a"
          version: "1.0.0"
          path: "node_modules/pkg-a"
        import:
          scope:
            source:
              path: "node_modules/pkg-a/src/index.js"
            module:
              name: "pkg-a"
              specifier: "pkg-a"
              version: "1.0.0"
              path: "node_modules/pkg-a"
          specifier: "#helpers"

      mappingAlias = await generator.apply depAlias
      assert.deepEqual {
        scope: "/node_modules/pkg-a@1.0.0/"
        specifier: "#helpers"
        target: "/node_modules/pkg-a@1.0.0/src/helpers/index.js"
      }, mappingAlias

    test "external sibling linked package (../../joy)", ->
      generator = Local.make root: "."
      depExternal =
        source:
          path: "../../joy/build/node/src/index.js"
        module:
          name: "joy"
          scope: "dashkite"
          specifier: "@dashkite/joy"
          version: "1.0.0"
          path: "../../joy"
        import:
          scope:
            source:
              path: "src/index.js"
            module:
              name: "my-app"
              specifier: "my-app"
              version: "1.0.0"
              path: "."
          specifier: "@dashkite/joy"

      mappingExternal = await generator.apply depExternal
      assert.deepEqual {
        scope: "/"
        specifier: "@dashkite/joy"
        target: "/node_modules/@dashkite/joy@1.0.0/build/node/src/index.js"
      }, mappingExternal

    test "external linked package imported by a scoped package", ->
      generator = Local.make root: "."
      depExternalScoped =
        source:
          path: "../../joy/build/node/src/index.js"
        module:
          name: "joy"
          scope: "dashkite"
          specifier: "@dashkite/joy"
          version: "1.0.0"
          path: "../../joy"
        import:
          scope:
            source:
              path: "node_modules/pkg-a/index.js"
            module:
              name: "pkg-a"
              specifier: "pkg-a"
              version: "1.0.0"
              path: "node_modules/pkg-a"
          specifier: "@dashkite/joy"

      mappingExternalScoped = await generator.apply depExternalScoped
      assert.deepEqual {
        scope: "/node_modules/pkg-a@1.0.0/"
        specifier: "@dashkite/joy"
        target: "/node_modules/pkg-a@1.0.0/node_modules/@dashkite/joy@1.0.0/build/node/src/index.js"
      }, mappingExternalScoped

    test "Atlas.generate integration", ->
      Generators.clear()
      Generators.register Local.make root: process.cwd()
      generated = await Atlas.generate [ "build/node/src/index.js" ], null,
        cwd: process.cwd()
        platform: "node"
        conditions: [ "node" ]
      assert.equal "object", typeof generated.imports
  ]

  process.exit if success then 0 else 1
