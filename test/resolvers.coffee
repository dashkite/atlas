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

RegistryTests =
  retrieval: ->
    Registry.register "test@param", { foo: "bar" }
    resolver = Registry.get "test@param"
    assert.equal resolver.foo, "bar"

MetaTests =
  match: ->
    Registry.register "test1", match: -> false
    Registry.register "test2", match: -> true
    Registry.register "test3", match: -> false
    resolver = Registry.make [ "test1", "test2", "test3" ]
    assert.equal ( resolver.match { source: "foo", cwd: "/root" } ), "test2"

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

ApplicationTests =
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

NodeTests =
  match: ->
    resolver = Node.make()
    assert resolver.match { source: "node_modules/foo/index.js", cwd: "/root" }

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

  resolve: ->
    resolver = Node.make()
    url = resolver.resolve "atlas://node/@dashkite/foo@1.0.0/build/index.js"
    assert typeof url == "string"

CdnTests =
  match: ->
    resolver = Factories.cdn()
    assert resolver.match { source: "node_modules/foo/index.js", cwd: "/root" }

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

LocalTests =
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

  resolve: ->
    resolver = Factories.local()
    target =
      "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
    url = resolver.resolve target
    assert typeof url == "string"

PresetTests =
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
      test "registers and retrieves resolvers", RegistryTests.retrieval
      test "Meta Resolver aggregates match", MetaTests.match
      test "Meta Resolver validates keys on encode", MetaTests.encode
      test "Meta Resolver validates keys on decode", MetaTests.decode
      test "Meta Resolver validates keys on resolve", MetaTests.resolve
    ]

  application: ->
    test "Application Resolver", [
      test "matches intra-package paths unconditionally",
        ApplicationTests.match
      test "rejects paths containing node_modules",
        ApplicationTests.reject.modules
      test "rejects paths escaping cwd (..)",
        ApplicationTests.reject.escaping
      test "encodes target to virtual root", ApplicationTests.encode
      test "decodes atlas URL", ApplicationTests.decode
      test "resolves to physical path", ApplicationTests.resolve
    ]

  node: ->
    test "Node Resolver", [
      test "matches paths containing node_modules", NodeTests.match
      test "rejects paths lacking node_modules", NodeTests.reject
      test "encodes dependency object", NodeTests.encode
      test "decodes atlas URL", NodeTests.decode.scoped
      test "decodes unscoped atlas URL", NodeTests.decode.unscoped
      test "resolves to physical path", NodeTests.resolve
    ]

  cdn: ->
    test "CDN Resolver", [
      test "matches paths containing node_modules", CdnTests.match
      test "encodes dependency object", CdnTests.encode
      test "decodes atlas URL", CdnTests.decode.scoped
      test "decodes unscoped atlas URL", CdnTests.decode.unscoped
      test "resolves using URL Codex template", CdnTests.resolve.scoped
      test "resolves unscoped using URL Codex template",
        CdnTests.resolve.unscoped
    ]

  local: ->
    test "Local Resolver", [
      test "matches configured deep glob patterns", LocalTests.match
      test "encodes dependency object", LocalTests.encode
      test "decodes scoped atlas URL", LocalTests.decode.scoped
      test "decodes unscoped atlas URL", LocalTests.decode.unscoped
      test "resolves to physical path", LocalTests.resolve
    ]

  presets: ->
    test "Resolver Presets", [
      test "Node preset exports keys", PresetTests.node
      test "Browser preset exports keys", PresetTests.browser
    ]

export default -> [
  Suites.registry()
  Suites.application()
  Suites.node()
  Suites.cdn()
  Suites.local()
  Suites.presets()
]