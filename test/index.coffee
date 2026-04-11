import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import lca from "../src/helpers/lca"
import groupByMapping from "../src/helpers/group-by-mapping"
import buildScopes from "../src/helpers/build-scopes"
import buildRoot from "../src/helpers/build-root"
import Map from "../src/helpers/import-map"

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
        imports: {}
        scopes:
          "/a/b/c/": "x": "v1"
          "/a/b/d/": "x": "v1"
          "/other/": "x": "v2"
      
      compacted = Map.compact map
      
      # x: v1 has 2 original scopes, which reduce to LCA /a/b/
      # x: v2 has 1 original scope /other/
      # Frequency: v1 (2) > v2 (1). v1 wins global imports.
      # v2 remains in its scope.
      
      expected =
        imports:
          x: "v1"
        scopes:
          "/other/":
            x: "v2"
            
      assert.deepEqual expected, compacted
  ]

  process.exit if success then 0 else 1
