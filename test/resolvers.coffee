import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { Registry, Application, Node, CDN, Local } from "../src/resolvers/index"
import presets from "../src/presets/index"

UNPKG_TEMPLATE = "https://unpkg.com/{scope?}/{versioned}/{path*}"

Factories =
  cdn: ->
    CDN.make template: UNPKG_TEMPLATE

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

Tests =
  registry:
    retrieval: ->
      Registry.register "test@param", { foo: "bar" }
      resolver = Registry.get "test@param"
      assert.equal resolver.foo, "bar"

  meta:
    match: ->
      Registry.register "test1", match: -> false
      Registry.register "test2", match: -> true
      Registry.register "test3", match: -> false
      resolver = Registry.make [ "test1", "test2", "test3" ]
      assert.equal ( resolver.match { source: "foo", cwd: "/root" }), "test2"

    encode: ->
      resolver = Factories.meta()
      resolver.encode { resolver: "test1", module: { name: "foo" }, path: "/" }
      invalid = { resolver: "test2", module: { name: "foo" }, path: "/" }
      assert.throws ( -> resolver.encode invalid ),
        "Resolver test2 not in configured keys"

    decode: ->
      resolver = Factories.meta()
      resolver.decode "atlas://test1/foo"
      assert.throws ( -> resolver.decode "atlas://test2/foo" ),
        "Resolver test2 not in configured keys"

    resolve: ->
      resolver = Factories.meta()
      resolver.resolve "atlas://test1/foo"
      assert.throws ( -> resolver.resolve "atlas://test2/foo" ),
        "Resolver test2 not in configured keys"

  application:
    match: ->
      resolver = Application.make()
      assert resolver.match { source: "src/index.coffee", cwd: "/root" }

    reject:
      modules: ->
        resolver = Application.make()
        source = "node_modules/foo/index.js"
        assert !resolver.match { source, cwd: "/root" }

      escaping: ->
        resolver = Application.make()
        assert !resolver.match { source: "../src/index.coffee", cwd: "/root" }

    encode: ->
      resolver = Application.make()
      url = resolver.encode
        resolver: "application"
        module: { name: "app" }
        path: "/src/index.coffee"
      assert.equal "atlas://application/src/index.coffee", url

    decode: ->
      resolver = Application.make()
      descriptor = resolver.decode "atlas://application/src/index.coffee"
      assert.equal descriptor.resolver, "application"
      assert.equal descriptor.path, "/src/index.coffee"

    resolve: ->
      resolver = Application.make()
      url = resolver.resolve "atlas://application/src/index.coffee"
      assert typeof url == "string"

  node:
    match: ->
      resolver = Node.make()
      source = "node_modules/foo/index.js"
      assert resolver.match { source, cwd: "/root" }

    reject: ->
      resolver = Node.make()
      assert !resolver.match { source: "src/index.coffee", cwd: "/root" }

    encode: ->
      resolver = Node.make()
      url = resolver.encode
        resolver: "node"
        module: { scope: "@dashkite", name: "foo", version: "1.0.0" }
        path: "/build/index.js"
      assert.equal "atlas://node/@dashkite/foo@1.0.0/build/index.js", url

    decode:
      scoped: ->
        resolver = Node.make()
        url = "atlas://node/@dashkite/foo@1.0.0/build/index.js"
        Assertions.module ( resolver.decode url ),
          resolver: "node", scope: "@dashkite"
          name: "foo", version: "1.0.0", path: "/build/index.js"

      unscoped: ->
        resolver = Node.make()
        url = "atlas://node/foo@1.0.0/build/index.js"
        Assertions.module ( resolver.decode url ),
          resolver: "node", scope: undefined
          name: "foo", version: "1.0.0", path: "/build/index.js"

    resolve:
      scoped: ->
        resolver = Node.make()
        url = resolver.resolve "atlas://node/@dashkite/foo@1.0.0/build/index.js"
        assert typeof url == "string"

      packageRoot:
        scoped: ->
          resolver = Node.make()
          url = resolver.resolve "atlas://node/@dashkite/foo@1.0.0"
          assert typeof url == "string"
          assert url.endsWith "node_modules/@dashkite/foo"

        unscoped: ->
          resolver = Node.make()
          url = resolver.resolve "atlas://node/foo@1.0.0"
          assert typeof url == "string"
          assert url.endsWith "node_modules/foo"

  cdn:
    match: ->
      resolver = Factories.cdn()
      source = "node_modules/foo/index.js"
      assert resolver.match { source, cwd: "/root" }

    encode: ->
      resolver = Factories.cdn()
      url = resolver.encode
        resolver: "cdn@unpkg"
        module: { scope: "@dashkite", name: "foo", version: "1.0.0" }
        path: "/build/index.js"
      assert.equal "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js", url

    decode:
      scoped: ->
        resolver = Factories.cdn()
        url = "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js"
        descriptor = resolver.decode url
        assert.equal descriptor.resolver, "cdn@unpkg"
        assert.equal descriptor.module.scope, "@dashkite"

      unscoped: ->
        resolver = Factories.cdn()
        url = "atlas://cdn@unpkg/foo@1.0.0/build/index.js"
        Assertions.module ( resolver.decode url ),
          resolver: "cdn@unpkg", scope: undefined
          name: "foo", version: "1.0.0", path: "/build/index.js"

    resolve:
      scoped: ->
        resolver = Factories.cdn()
        target = "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js"
        url = resolver.resolve target
        assert.equal "https://unpkg.com/@dashkite/foo@1.0.0/build/index.js", url

      unscoped: ->
        resolver = Factories.cdn()
        url = resolver.resolve "atlas://cdn@unpkg/foo@1.0.0/build/index.js"
        assert.equal "https://unpkg.com/foo@1.0.0/build/index.js", url

      packageRoot:
        scoped: ->
          resolver = Factories.cdn()
          url = resolver.resolve "atlas://cdn@unpkg/@dashkite/foo@1.0.0"
          assert.equal "https://unpkg.com/@dashkite/foo@1.0.0", url

        unscoped: ->
          resolver = Factories.cdn()
          url = resolver.resolve "atlas://cdn@unpkg/foo@1.0.0"
          assert.equal "https://unpkg.com/foo@1.0.0", url

  local:
    match: ->
      resolver = Factories.local()
      assert resolver.match
        source: "/root/.tempo/repos/foo/build/node/src/index.js"
        cwd: "/root/app"
      assert !resolver.match { source: "/other/foo/index.js", cwd: "/root/app" }

    encode: ->
      resolver = Factories.local()
      url = resolver.encode
        resolver: "local@central-park"
        module: { scope: "@scope", name: "foo", version: "1.0.0" }
        path: "/build/node/src/index.js"
      expected =
        "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
      assert.equal expected, url

    decode:
      scoped: ->
        resolver = Factories.local()
        url =
          "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
        Assertions.module ( resolver.decode url ),
          resolver: "local@central-park", scope: "@scope"
          name: "foo", version: "1.0.0", path: "/build/node/src/index.js"

      unscoped: ->
        resolver = Factories.local()
        url = "atlas://local@central-park/foo@1.0.0/build/node/src/index.js"
        Assertions.module ( resolver.decode url ),
          resolver: "local@central-park", scope: undefined
          name: "foo", version: "1.0.0", path: "/build/node/src/index.js"

    resolve:
      scoped: ->
        resolver = Factories.local()
        target =
          "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
        url = resolver.resolve target
        assert typeof url == "string"

      packageRoot:
        scoped: ->
          resolver = Factories.local()
          url = resolver.resolve "atlas://local@central-park/@scope/foo@1.0.0"
          assert.equal "file:///root", url

        unscoped: ->
          resolver = Factories.local()
          url = resolver.resolve "atlas://local@central-park/foo@1.0.0"
          assert.equal "file:///root", url

  presets:
    node: ->
      keys = presets.node
      assert Array.isArray keys
      assert keys.includes "application"
      assert keys.includes "node"

    browser: ->
      keys = presets.browser
      assert Array.isArray keys
      assert keys.includes "application"
      assert keys.some ( key ) -> key.startsWith "cdn"

Suites =
  registry: ->
    test "Registry & Meta Resolver", [
      test "registers and retrieves resolvers", Tests.registry.retrieval
      test "Meta Resolver aggregates match", Tests.meta.match
      test "Meta Resolver validates keys on encode", Tests.meta.encode
      test "Meta Resolver validates keys on decode", Tests.meta.decode
      test "Meta Resolver validates keys on resolve", Tests.meta.resolve
    ]

  application: ->
    test "Application Resolver", [
      test "matches intra-package paths unconditionally",
        Tests.application.match
      test "rejects paths containing node_modules",
        Tests.application.reject.modules
      test "rejects paths escaping cwd (..)",
        Tests.application.reject.escaping
      test "encodes target to virtual root", Tests.application.encode
      test "decodes atlas URL", Tests.application.decode
      test "resolves to physical path", Tests.application.resolve
    ]

  node: ->
    test "Node Resolver", [
      test "matches paths containing node_modules", Tests.node.match
      test "rejects paths lacking node_modules", Tests.node.reject
      test "encodes dependency object", Tests.node.encode
      test "decodes atlas URL", Tests.node.decode.scoped
      test "decodes unscoped atlas URL", Tests.node.decode.unscoped
      test "resolves to physical path", Tests.node.resolve.scoped
      test "resolves scoped package-root URL to physical path",
        Tests.node.resolve.packageRoot.scoped
      test "resolves unscoped package-root URL to physical path",
        Tests.node.resolve.packageRoot.unscoped
    ]

  cdn: ->
    test "CDN Resolver", [
      test "matches paths containing node_modules", Tests.cdn.match
      test "encodes dependency object", Tests.cdn.encode
      test "decodes atlas URL", Tests.cdn.decode.scoped
      test "decodes unscoped atlas URL", Tests.cdn.decode.unscoped
      test "resolves using URL Codex template", Tests.cdn.resolve.scoped
      test "resolves unscoped using URL Codex template",
        Tests.cdn.resolve.unscoped
      test "resolves scoped package-root URL using template",
        Tests.cdn.resolve.packageRoot.scoped
      test "resolves unscoped package-root URL using template",
        Tests.cdn.resolve.packageRoot.unscoped
    ]

  local: ->
    test "Local Resolver", [
      test "matches configured deep glob patterns", Tests.local.match
      test "encodes dependency object", Tests.local.encode
      test "decodes scoped atlas URL", Tests.local.decode.scoped
      test "decodes unscoped atlas URL", Tests.local.decode.unscoped
      test "resolves to physical path", Tests.local.resolve.scoped
      test "resolves scoped package-root URL to physical path",
        Tests.local.resolve.packageRoot.scoped
      test "resolves unscoped package-root URL to physical path",
        Tests.local.resolve.packageRoot.unscoped
    ]

  presets: ->
    test "Resolver Presets", [
      test "Node preset exports keys", Tests.presets.node
      test "Browser preset exports keys", Tests.presets.browser
    ]

export default -> [
  Suites.registry()
  Suites.application()
  Suites.node()
  Suites.cdn()
  Suites.local()
  Suites.presets()
]