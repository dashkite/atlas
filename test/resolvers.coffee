import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import Resolvers, { Application, NPM, CDN, Local } from "../src/resolvers/index"
import presets from "../src/presets/index"

export default -> [
  test "Application Resolver", -> [
    test "matches intra-package paths unconditionally", ->
      resolver = Application.make()
      assert resolver.match "src/index.coffee"
      assert resolver.match { source: { path: "src/index.coffee" } }

    test "rejects paths containing node_modules", ->
      resolver = Application.make()
      assert !resolver.match "node_modules/foo/index.js"
      assert !resolver.match { source: { path: "node_modules/foo/index.js" } }

    test "rejects paths escaping root (..)", ->
      resolver = Application.make()
      assert !resolver.match "../src/index.coffee"

    test "encodes target to virtual root", ->
      resolver = Application.make()
      url = resolver.encode "src/index.coffee"
      assert.equal "atlas://application/src/index.coffee", url
  ]

  test "NPM Resolver", -> [
    test "matches paths containing node_modules", ->
      resolver = NPM.make()
      assert resolver.match "node_modules/foo/index.js"
      assert resolver.match { source: { path: "node_modules/foo/index.js" } }

    test "rejects paths lacking node_modules", ->
      resolver = NPM.make()
      assert !resolver.match "src/index.coffee"

    test "encodes dependency object using module data", ->
      resolver = NPM.make()
      target =
        source: path: "node_modules/foo/build/index.js"
        module: specifier: "foo", version: "1.0.0", path: "node_modules/foo"
      url = resolver.encode target
      assert.equal "atlas://npm/foo@1.0.0/build/index.js", url
  ]

  test "CDN Resolver", -> [
    test "matches paths containing node_modules", ->
      resolver = CDN.make template: "https://unpkg.com/:package@:version/*subpath"
      assert resolver.match "node_modules/foo/index.js"
      
    test "encodes via template interpolation", ->
      resolver = CDN.make template: "https://unpkg.com/:package@:version/*subpath"
      target =
        source: path: "node_modules/@dashkite/foo/build/index.js"
        module: specifier: "@dashkite/foo", version: "1.0.0", path: "node_modules/@dashkite/foo"
      
      url = resolver.encode target
      assert url.includes "unpkg.com/@dashkite/foo@1.0.0/build/index.js"
      assert url.startsWith "atlas://cdn/"
  ]

  test "Local Resolver", -> [
    test "defaults to deep workspace patterns", ->
      resolver = Local.make()
      assert resolver.match "../foo/build/node/src/index.js"
      assert resolver.match "packages/foo/build/node/src/index.js"
      assert !resolver.match "src/index.coffee"
    
    test "matches configured deep glob patterns", ->
      resolver = Local.make patterns: [ "**/.tempo/repos/**/*" ]
      assert resolver.match "../.tempo/repos/foo/build/node/src/index.js"
      assert resolver.match ".tempo/repos/enchant/build/node/src/action.js"
      assert !resolver.match "../foo/index.js"

    test "encodes symlinked dependencies with module data", ->
      resolver = Local.make patterns: [ "**/.tempo/repos/**/*" ]
      target =
        source: path: "../.tempo/repos/foo/build/node/src/index.js"
        module: specifier: "@scope/foo", version: "1.0.0", path: "../.tempo/repos/foo"
      url = resolver.encode target
      assert.equal "atlas://local/@scope/foo@1.0.0/build/node/src/index.js", url
  ]
  
  test "Resolver Presets", -> [
    test "Node preset yields standard registry", ->
      registry = presets.node local: { patterns: ["**/.tempo/repos/*"] }
      assert.equal registry.length, 3
      assert typeof registry[0].match == "function"
      
    test "Browser preset yields CDN registry", ->
      registry = presets.browser local: { patterns: ["**/.tempo/repos/*"] }, cdn: { template: "..." }
      assert.equal registry.length, 3
  ]
]
