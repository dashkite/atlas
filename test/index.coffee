import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import groupByMapping from "../src/helpers/import-map/group-by-mapping"
import groupBySpecifier from "../src/helpers/import-map/group-by-specifier"
import Map from "../src/helpers/import-map"
import resolve from "../src/helpers/import-map/resolve"

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
      assert.equal "v2",
        resolve { map: optimized, specifier: "x", base: "/a/3/" }
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

  process.exit if success then 0 else 1
