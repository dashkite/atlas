import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import lca from "../src/helpers/import-map/lca"
import groupByMapping from "../src/helpers/import-map/group-by-mapping"
import buildScopes from "../src/helpers/import-map/build-scopes"
import buildRoot from "../src/helpers/import-map/build-root"
import Map from "../src/helpers/import-map"
import resolve from "../src/helpers/import-map/resolve"

do ->
  print await test "LCA", [
    test "single tree", ->
      scopes = [
        "/a/b/c/"
        "/a/b/d/"
      ]
      assert.deepEqual new Set([ "/a/b/" ]), lca scopes

    test "multiple trees", ->
      scopes = [
        "https://cdn.com/a/b/c/"
        "https://cdn.com/a/b/d/"
        "https://other.com/x/y/"
      ]
      assert.deepEqual new Set([
        "https://cdn.com/a/b/"
        "https://other.com/x/y/"
      ]), lca scopes
  ]

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
        { mapping: { specifier: "x", target: "v1" }, scopes: [ "a" ]}
        { mapping: { specifier: "x", target: "v2" }, scopes: [ "b", "c" ]}
        { mapping: { specifier: "y", target: "v1" }, scopes: [ "c" ]}
      ]

      assert.deepEqual expected,
        normalize groupByMapping scopes

  ]

  print await test "buildScopes", [
    test "basic building", ->
      groups = [
        { mapping: { specifier: "x", target: "v1" }, scopes: new Set [ "a" ]}
        { mapping: { specifier: "x", target: "v2" }, scopes: new Set [ "b", "c" ]}
        { mapping: { specifier: "y", target: "v1" }, scopes: new Set [ "c" ]}
      ]

      expected =
        a: x: "v1"
        b: x: "v2"
        c:
          x: "v2"
          y: "v1"

      assert.deepEqual expected, buildScopes groups
  ]

  print await test "buildRoot", [
    test "frequency sorting and conflicts", ->
      scopes =
        a: x: "v1"
        b: x: "v2"
        c:
          x: "v2"
          y: "v1"

      # x: v2 has 2 scopes, x: v1 has 1. x: v2 wins.
      # y: v1 has 1 scope and no conflicts.
      expected = 
        imports:
          x: "v2"
          y: "v1"
        scopes:
          a: x: "v1"

      assert.deepEqual expected, buildRoot scopes

    test "root scope prioritization", ->
      scopes =
        "/": x: "v1"
        "a": x: "v2"
        "b": x: "v2"
        "c": x: "v2"
      
      # x: v2 has more scopes (3) but x: v1 is in root scope (/).
      # Root scope wins.
      expected = 
        imports:
          x: "v1"
        scopes:
          a: x: "v2"
          b: x: "v2"
          c: x: "v2"
      
      assert.deepEqual expected, buildRoot scopes
  ]

  print await test "Map.compact", [
    test "full integration", ->
      map = 
        imports:
          "z": "v1"
        scopes:
          "/a/b/c/": "x": "v1"
          "/a/b/d/": "x": "v1"
          "/other/": "x": "v2"
      
      compacted = Map.compact map
      
      # z: v1 stays in imports
      # x: v1 (at /a/b/c/ and /a/b/d/) reduces to LCA /a/b/
      # x: v2 stays in /other/
      
      expected =
        imports:
          z: "v1"
        scopes:
          "/a/b/":
            x: "v1"
          "/other/":
            x: "v2"
            
      assert.deepEqual expected, compacted
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
      
      # Specifier x is NOT in /a/, so it falls back to global
      assert.equal "global",
        resolve { map, specifier: "x", base: "/a/b.js" }
  ]

  process.exit if success then 0 else 1
