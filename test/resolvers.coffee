import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { Registry, Application, Node, CDN, Local } from "../src/resolvers/index"
import presets from "../src/presets/index"

export default -> [
  test "Registry & Meta Resolver", -> [
    test "registers and retrieves resolvers", ->
      Registry.register "test@param", { foo: "bar" }
      resolver = Registry.get "test@param"
      assert.equal resolver.foo, "bar"

    test "Meta Resolver aggregates match", ->
      Registry.register "test1", match: -> false
      Registry.register "test2", match: -> true
      Registry.register "test3", match: -> false
      meta = Registry.make ["test1", "test2", "test3"]
      assert.equal meta.match({ source: "foo", cwd: "/root" }), "test2"
      
    test "Meta Resolver validates keys on encode/decode/resolve", ->
      Registry.register "test1", 
        encode: -> "atlas://test1"
        decode: -> {}
        resolve: -> "http://test1"
      meta = Registry.make ["test1"]
      
      # valid
      meta.encode { resolver: "test1", module: { name: "foo" }, path: "/" }
      meta.decode "atlas://test1/foo"
      meta.resolve "atlas://test1/foo"
      
      # invalid
      assert.throws -> meta.encode { resolver: "test2", module: { name: "foo" }, path: "/" }
      assert.throws -> meta.decode "atlas://test2/foo"
      assert.throws -> meta.resolve "atlas://test2/foo"
  ]

  test "Application Resolver", -> [
    test "matches intra-package paths unconditionally", ->
      resolver = Application.make()
      assert resolver.match { source: "src/index.coffee", cwd: "/root" }

    test "rejects paths containing node_modules", ->
      resolver = Application.make()
      assert !resolver.match { source: "node_modules/foo/index.js", cwd: "/root" }

    test "rejects paths escaping cwd (..)", ->
      resolver = Application.make()
      assert !resolver.match { source: "../src/index.coffee", cwd: "/root" }

    test "encodes target to virtual root", ->
      resolver = Application.make()
      url = resolver.encode {
        resolver: "application"
        module: { name: "app" }
        path: "/src/index.coffee"
      }
      assert.equal "atlas://application/src/index.coffee", url
      
    test "decodes atlas URL", ->
      resolver = Application.make()
      descriptor = resolver.decode "atlas://application/src/index.coffee"
      assert.equal descriptor.resolver, "application"
      assert.equal descriptor.path, "/src/index.coffee"
      
    test "resolves to physical path", ->
      resolver = Application.make()
      url = resolver.resolve "atlas://application/src/index.coffee"
      assert typeof url == "string"
  ]

  test "Node Resolver", -> [
    test "matches paths containing node_modules", ->
      resolver = Node.make()
      assert resolver.match { source: "node_modules/foo/index.js", cwd: "/root" }

    test "rejects paths lacking node_modules", ->
      resolver = Node.make()
      assert !resolver.match { source: "src/index.coffee", cwd: "/root" }

    test "encodes dependency object", ->
      resolver = Node.make()
      url = resolver.encode {
        resolver: "node"
        module: { scope: "@dashkite", name: "foo", version: "1.0.0" }
        path: "/build/index.js"
      }
      assert.equal "atlas://node/@dashkite/foo@1.0.0/build/index.js", url
      
    test "decodes atlas URL", ->
      resolver = Node.make()
      desc = resolver.decode "atlas://node/@dashkite/foo@1.0.0/build/index.js"
      assert.equal desc.resolver, "node"
      assert.equal desc.module.scope, "@dashkite"
      assert.equal desc.module.name, "foo"
      assert.equal desc.module.version, "1.0.0"
      assert.equal desc.path, "/build/index.js"
      
    test "resolves to physical path", ->
      resolver = Node.make()
      url = resolver.resolve "atlas://node/@dashkite/foo@1.0.0/build/index.js"
      assert typeof url == "string"
  ]
  
  test "CDN Resolver", -> [
    test "matches paths containing node_modules", ->
      resolver = CDN.make template: "https://unpkg.com/{scope?}/{versioned}/{path*}"
      assert resolver.match { source: "node_modules/foo/index.js", cwd: "/root" }
      
    test "encodes dependency object", ->
      resolver = CDN.make template: "https://unpkg.com/{scope?}/{versioned}/{path*}"
      url = resolver.encode {
        resolver: "cdn@unpkg"
        module: { scope: "@dashkite", name: "foo", version: "1.0.0" }
        path: "/build/index.js"
      }
      assert.equal "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js", url
      
    test "decodes atlas URL", ->
      resolver = CDN.make template: "https://unpkg.com/{scope?}/{versioned}/{path*}"
      desc = resolver.decode "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js"
      assert.equal desc.resolver, "cdn@unpkg"
      assert.equal desc.module.scope, "@dashkite"
      
    test "resolves using URL Codex template", ->
      resolver = CDN.make template: "https://unpkg.com/{scope?}/{versioned}/{path*}"
      url = resolver.resolve "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js"
      assert.equal "https://unpkg.com/@dashkite/foo@1.0.0/build/index.js", url
      
    test "resolves unscoped using URL Codex template", ->
      resolver = CDN.make template: "https://unpkg.com/{scope?}/{versioned}/{path*}"
      url = resolver.resolve "atlas://cdn@unpkg/foo@1.0.0/build/index.js"
      assert.equal "https://unpkg.com/foo@1.0.0/build/index.js", url
  ]

  test "Local Resolver", -> [
    test "matches configured deep glob patterns", ->
      resolver = Local.make root: "/root", patterns: [ "**/.tempo/repos/**/*" ]
      assert resolver.match { source: "/root/.tempo/repos/foo/build/node/src/index.js", cwd: "/root/app" }
      assert !resolver.match { source: "/other/foo/index.js", cwd: "/root/app" }

    test "encodes dependency object", ->
      resolver = Local.make root: "/root", patterns: [ "**/.tempo/repos/**/*" ]
      url = resolver.encode {
        resolver: "local@central-park"
        module: { scope: "@scope", name: "foo", version: "1.0.0" }
        path: "/build/node/src/index.js"
      }
      assert.equal "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js", url
      
    test "resolves to physical path", ->
      resolver = Local.make root: "/root", patterns: [ "**/.tempo/repos/**/*" ]
      url = resolver.resolve "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
      assert typeof url == "string"
  ]

  test "Resolver Presets", -> [
    test "Node preset exports keys", ->
      keys = presets.node
      assert Array.isArray(keys)
      assert keys.includes("application")
      assert keys.includes("node")
      
    test "Browser preset exports keys", ->
      keys = presets.browser
      assert Array.isArray(keys)
      assert keys.includes("application")
      assert.ok keys.some (k) -> k.startsWith("cdn")
  ]
]
