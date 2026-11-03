import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { isString, isArray } from "@dashkite/joy/type"
import { Registry, Application, Node, CDN, Local } from "../src/resolvers/index"
import presets from "../src/presets/index"

template = "https://unpkg.com/{scope?}/{versioned}/{path*}"

Factories =
  cdn: ->
    CDN.make { template }

  local: ->
    Local.make root: "/root", patterns: [ "**/.tempo/repos/**/*" ]

  meta: ->
    Stub.register "test1"
    Stub.register "test2"
    Registry.make [ "test1" ]

Assertions =
  module: ( descriptor, expected ) ->
    assert.equal descriptor.resolver, expected.resolver
    assert.equal descriptor.module.scope, expected.scope
    assert.equal descriptor.module.name, expected.name
    assert.equal descriptor.module.version, expected.version
    assert.equal descriptor.path, expected.path

Stub =
  register: ( name ) ->
    Registry.register name,
      encode: -> "atlas://#{name}"
      decode: -> {}
      resolve: -> "http://#{name}"

export default -> [
  test "Registry & Meta Resolver", [
    test "registers and retrieves resolvers", ->
      Registry.register "test@param", { foo: "bar" }
      resolver = Registry.get "test@param"
      assert.equal resolver.foo, "bar"

    test "Meta Resolver aggregates match", ->
      Registry.register "test1", match: -> false
      Registry.register "test2", match: -> true
      Registry.register "test3", match: -> false
      resolver = Registry.make [ "test1", "test2", "test3" ]
      assert.equal ( resolver.match { source: "foo", cwd: "/root" }), "test2"

    test "Meta Resolver validates keys on encode", ->
      resolver = Factories.meta()
      resolver.encode { resolver: "test1", module: { name: "foo" }, path: "/" }
      invalid = { resolver: "test2", module: { name: "foo" }, path: "/" }
      assert.throws ( -> resolver.encode invalid ),
        "Resolver test2 not in configured keys"

    test "Meta Resolver validates keys on decode", ->
      resolver = Factories.meta()
      resolver.decode "atlas://test1/foo"
      assert.throws ( -> resolver.decode "atlas://test2/foo" ),
        "Resolver test2 not in configured keys"

    test "Meta Resolver validates keys on resolve", ->
      resolver = Factories.meta()
      resolver.resolve "atlas://test1/foo"
      assert.throws ( -> resolver.resolve "atlas://test2/foo" ),
        "Resolver test2 not in configured keys"
  ]

  test "Application Resolver", [
    test "matches intra-package paths unconditionally", ->
      resolver = Application.make()
      assert resolver.match { source: "src/index.coffee", cwd: "/root" }

    test "rejects paths containing node_modules", ->
      resolver = Application.make()
      source = "node_modules/foo/index.js"
      assert !resolver.match { source, cwd: "/root" }

    test "rejects paths escaping cwd (..)", ->
      resolver = Application.make()
      assert !resolver.match { source: "../src/index.coffee", cwd: "/root" }

    test "encodes target to virtual root", ->
      resolver = Application.make()
      url = resolver.encode
        resolver: "application"
        module: { name: "app" }
        path: "/src/index.coffee"
      assert.equal "atlas://application/src/index.coffee", url

    test "decodes atlas URL", ->
      resolver = Application.make()
      descriptor = resolver.decode "atlas://application/src/index.coffee"
      assert.equal descriptor.resolver, "application"
      assert.equal descriptor.path, "/src/index.coffee"

    test "resolves to physical path", ->
      resolver = Application.make()
      url = resolver.resolve "atlas://application/src/index.coffee"
      assert isString url
  ]

  test "Node Resolver", [
    test "matches paths containing node_modules", ->
      resolver = Node.make()
      source = "node_modules/foo/index.js"
      assert resolver.match { source, cwd: "/root" }

    test "rejects paths lacking node_modules", ->
      resolver = Node.make()
      assert !resolver.match { source: "src/index.coffee", cwd: "/root" }

    test "encodes dependency object", ->
      resolver = Node.make()
      url = resolver.encode
        resolver: "node"
        module: { scope: "@dashkite", name: "foo", version: "1.0.0" }
        path: "/build/index.js"
      assert.equal "atlas://node/@dashkite/foo@1.0.0/build/index.js", url

    test "decodes atlas URL", ->
      resolver = Node.make()
      url = "atlas://node/@dashkite/foo@1.0.0/build/index.js"
      Assertions.module ( resolver.decode url ),
        resolver: "node", scope: "@dashkite"
        name: "foo", version: "1.0.0", path: "/build/index.js"

    test "decodes unscoped atlas URL", ->
      resolver = Node.make()
      url = "atlas://node/foo@1.0.0/build/index.js"
      Assertions.module ( resolver.decode url ),
        resolver: "node", scope: undefined
        name: "foo", version: "1.0.0", path: "/build/index.js"

    test "resolves to physical path", ->
      resolver = Node.make()
      url = resolver.resolve "atlas://node/@dashkite/foo@1.0.0/build/index.js"
      assert isString url

    test "resolves scoped package-root URL to physical path", ->
      resolver = Node.make()
      url = resolver.resolve "atlas://node/@dashkite/foo@1.0.0"
      assert isString url
      assert url.endsWith "node_modules/@dashkite/foo"

    test "resolves unscoped package-root URL to physical path", ->
      resolver = Node.make()
      url = resolver.resolve "atlas://node/foo@1.0.0"
      assert isString url
      assert url.endsWith "node_modules/foo"
  ]

  test "CDN Resolver", [
    test "matches paths containing node_modules", ->
      resolver = Factories.cdn()
      source = "node_modules/foo/index.js"
      assert resolver.match { source, cwd: "/root" }

    test "encodes dependency object", ->
      resolver = Factories.cdn()
      url = resolver.encode
        resolver: "cdn@unpkg"
        module: { scope: "@dashkite", name: "foo", version: "1.0.0" }
        path: "/build/index.js"
      assert.equal "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js", url

    test "decodes atlas URL", ->
      resolver = Factories.cdn()
      url = "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js"
      descriptor = resolver.decode url
      assert.equal descriptor.resolver, "cdn@unpkg"
      assert.equal descriptor.module.scope, "@dashkite"

    test "decodes unscoped atlas URL", ->
      resolver = Factories.cdn()
      url = "atlas://cdn@unpkg/foo@1.0.0/build/index.js"
      Assertions.module ( resolver.decode url ),
        resolver: "cdn@unpkg", scope: undefined
        name: "foo", version: "1.0.0", path: "/build/index.js"

    test "resolves using URL Codex template", ->
      resolver = Factories.cdn()
      target = "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js"
      url = resolver.resolve target
      assert.equal "https://unpkg.com/@dashkite/foo@1.0.0/build/index.js", url

    test "resolves unscoped using URL Codex template", ->
      resolver = Factories.cdn()
      url = resolver.resolve "atlas://cdn@unpkg/foo@1.0.0/build/index.js"
      assert.equal "https://unpkg.com/foo@1.0.0/build/index.js", url

    test "resolves scoped package-root URL using template", ->
      resolver = Factories.cdn()
      url = resolver.resolve "atlas://cdn@unpkg/@dashkite/foo@1.0.0"
      assert.equal "https://unpkg.com/@dashkite/foo@1.0.0", url

    test "resolves unscoped package-root URL using template", ->
      resolver = Factories.cdn()
      url = resolver.resolve "atlas://cdn@unpkg/foo@1.0.0"
      assert.equal "https://unpkg.com/foo@1.0.0", url
  ]

  test "Local Resolver", [
    test "matches configured deep glob patterns", ->
      resolver = Factories.local()
      context =
        source: "/root/.tempo/repos/foo/build/node/src/index.js"
        cwd: "/root/app"
      assert resolver.match context
      assert !resolver.match { source: "/other/foo/index.js", cwd: "/root/app" }

    test "encodes dependency object", ->
      resolver = Factories.local()
      url = resolver.encode
        resolver: "local@central-park"
        module: { scope: "@scope", name: "foo", version: "1.0.0" }
        path: "/build/node/src/index.js"
      expected =
        "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
      assert.equal expected, url

    test "decodes scoped atlas URL", ->
      resolver = Factories.local()
      url =
        "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
      Assertions.module ( resolver.decode url ),
        resolver: "local@central-park", scope: "@scope"
        name: "foo", version: "1.0.0", path: "/build/node/src/index.js"

    test "decodes unscoped atlas URL", ->
      resolver = Factories.local()
      url = "atlas://local@central-park/foo@1.0.0/build/node/src/index.js"
      Assertions.module ( resolver.decode url ),
        resolver: "local@central-park", scope: undefined
        name: "foo", version: "1.0.0", path: "/build/node/src/index.js"

    test "resolves to physical path", ->
      resolver = Factories.local()
      target =
        "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
      url = resolver.resolve target
      assert isString url

    test "resolves scoped package-root URL to physical path", ->
      resolver = Factories.local()
      url = resolver.resolve "atlas://local@central-park/@scope/foo@1.0.0"
      assert.equal "file:///root", url

    test "resolves unscoped package-root URL to physical path", ->
      resolver = Factories.local()
      url = resolver.resolve "atlas://local@central-park/foo@1.0.0"
      assert.equal "file:///root", url
  ]

  test "Resolver Presets", [
    test "Node preset exports keys", ->
      keys = presets.node
      assert isArray keys
      assert keys.includes "application"
      assert keys.includes "node"

    test "Browser preset exports keys", ->
      keys = presets.browser
      assert isArray keys
      assert keys.includes "application"
      assert keys.some ( key ) -> key.startsWith "cdn"
  ]
]