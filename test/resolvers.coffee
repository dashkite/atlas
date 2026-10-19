import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { Registry, Application, Node, CDN, Local } from "../src/resolvers/index"
import presets from "../src/presets/index"

unpkgTemplate = "https://unpkg.com/{scope?}/{versioned}/{path*}"

createCdnResolver = ->
  CDN.make template: unpkgTemplate

createLocalResolver = ->
  Local.make root: "/root", patterns: [ "**/.tempo/repos/**/*" ]

assertDecodedModule = ( descriptor, expected ) ->
  assert.equal descriptor.resolver, expected.resolver
  assert.equal descriptor.module.scope, expected.scope
  assert.equal descriptor.module.name, expected.name
  assert.equal descriptor.module.version, expected.version
  assert.equal descriptor.path, expected.path

registerStubResolver = ( name ) ->
  Registry.register name,
    encode: -> "atlas://#{name}"
    decode: -> {}
    resolve: -> "http://#{name}"

createMetaResolver = ->
  registerStubResolver "test1"
  registerStubResolver "test2"
  Registry.make [ "test1" ]

testRegistryRetrieval = ->
  Registry.register "test@param", { foo: "bar" }
  resolver = Registry.get "test@param"
  assert.equal resolver.foo, "bar"

testMetaMatch = ->
  Registry.register "test1", match: -> false
  Registry.register "test2", match: -> true
  Registry.register "test3", match: -> false
  resolver = Registry.make [ "test1", "test2", "test3" ]
  assert.equal ( resolver.match { source: "foo", cwd: "/root" } ), "test2"

testMetaEncodeValidation = ->
  resolver = createMetaResolver()
  resolver.encode { resolver: "test1", module: { name: "foo" }, path: "/" }
  invalid = { resolver: "test2", module: { name: "foo" }, path: "/" }
  assert.throws ( -> resolver.encode invalid ),
    "Resolver test2 not in configured keys"

testMetaDecodeValidation = ->
  resolver = createMetaResolver()
  resolver.decode "atlas://test1/foo"
  assert.throws ( -> resolver.decode "atlas://test2/foo" ),
    "Resolver test2 not in configured keys"

testMetaResolveValidation = ->
  resolver = createMetaResolver()
  resolver.resolve "atlas://test1/foo"
  assert.throws ( -> resolver.resolve "atlas://test2/foo" ),
    "Resolver test2 not in configured keys"

registrySuite = ->
  test "Registry & Meta Resolver", [
    test "registers and retrieves resolvers", testRegistryRetrieval
    test "Meta Resolver aggregates match", testMetaMatch
    test "Meta Resolver validates keys on encode", testMetaEncodeValidation
    test "Meta Resolver validates keys on decode", testMetaDecodeValidation
    test "Meta Resolver validates keys on resolve", testMetaResolveValidation
  ]

testAppMatchIntra = ->
  resolver = Application.make()
  assert resolver.match { source: "src/index.coffee", cwd: "/root" }

testAppRejectNodeModules = ->
  resolver = Application.make()
  assert !resolver.match { source: "node_modules/foo/index.js", cwd: "/root" }

testAppRejectEscapingPath = ->
  resolver = Application.make()
  assert !resolver.match { source: "../src/index.coffee", cwd: "/root" }

testAppEncode = ->
  resolver = Application.make()
  url = resolver.encode
    resolver: "application"
    module: { name: "app" }
    path: "/src/index.coffee"
  assert.equal "atlas://application/src/index.coffee", url

testAppDecode = ->
  resolver = Application.make()
  descriptor = resolver.decode "atlas://application/src/index.coffee"
  assert.equal descriptor.resolver, "application"
  assert.equal descriptor.path, "/src/index.coffee"

testAppResolve = ->
  resolver = Application.make()
  url = resolver.resolve "atlas://application/src/index.coffee"
  assert typeof url == "string"

applicationSuite = ->
  test "Application Resolver", [
    test "matches intra-package paths unconditionally", testAppMatchIntra
    test "rejects paths containing node_modules", testAppRejectNodeModules
    test "rejects paths escaping cwd (..)", testAppRejectEscapingPath
    test "encodes target to virtual root", testAppEncode
    test "decodes atlas URL", testAppDecode
    test "resolves to physical path", testAppResolve
  ]

testNodeMatch = ->
  resolver = Node.make()
  assert resolver.match { source: "node_modules/foo/index.js", cwd: "/root" }

testNodeRejectNonNodeModules = ->
  resolver = Node.make()
  assert !resolver.match { source: "src/index.coffee", cwd: "/root" }

testNodeEncode = ->
  resolver = Node.make()
  url = resolver.encode
    resolver: "node"
    module: { scope: "@dashkite", name: "foo", version: "1.0.0" }
    path: "/build/index.js"
  assert.equal "atlas://node/@dashkite/foo@1.0.0/build/index.js", url

testNodeDecodeScoped = ->
  resolver = Node.make()
  url = "atlas://node/@dashkite/foo@1.0.0/build/index.js"
  assertDecodedModule ( resolver.decode url ),
    resolver: "node", scope: "@dashkite"
    name: "foo", version: "1.0.0", path: "/build/index.js"

testNodeDecodeUnscoped = ->
  resolver = Node.make()
  url = "atlas://node/foo@1.0.0/build/index.js"
  assertDecodedModule ( resolver.decode url ),
    resolver: "node", scope: undefined
    name: "foo", version: "1.0.0", path: "/build/index.js"

testNodeResolve = ->
  resolver = Node.make()
  url = resolver.resolve "atlas://node/@dashkite/foo@1.0.0/build/index.js"
  assert typeof url == "string"

nodeSuite = ->
  test "Node Resolver", [
    test "matches paths containing node_modules", testNodeMatch
    test "rejects paths lacking node_modules", testNodeRejectNonNodeModules
    test "encodes dependency object", testNodeEncode
    test "decodes atlas URL", testNodeDecodeScoped
    test "decodes unscoped atlas URL", testNodeDecodeUnscoped
    test "resolves to physical path", testNodeResolve
  ]

testCdnMatch = ->
  resolver = createCdnResolver()
  assert resolver.match { source: "node_modules/foo/index.js", cwd: "/root" }

testCdnEncode = ->
  resolver = createCdnResolver()
  url = resolver.encode
    resolver: "cdn@unpkg"
    module: { scope: "@dashkite", name: "foo", version: "1.0.0" }
    path: "/build/index.js"
  assert.equal "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js", url

testCdnDecodeScoped = ->
  resolver = createCdnResolver()
  descriptor =
    resolver.decode "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js"
  assert.equal descriptor.resolver, "cdn@unpkg"
  assert.equal descriptor.module.scope, "@dashkite"

testCdnDecodeUnscoped = ->
  resolver = createCdnResolver()
  url = "atlas://cdn@unpkg/foo@1.0.0/build/index.js"
  assertDecodedModule ( resolver.decode url ),
    resolver: "cdn@unpkg", scope: undefined
    name: "foo", version: "1.0.0", path: "/build/index.js"

testCdnResolveScoped = ->
  resolver = createCdnResolver()
  url = resolver.resolve "atlas://cdn@unpkg/@dashkite/foo@1.0.0/build/index.js"
  assert.equal "https://unpkg.com/@dashkite/foo@1.0.0/build/index.js", url

testCdnResolveUnscoped = ->
  resolver = createCdnResolver()
  url = resolver.resolve "atlas://cdn@unpkg/foo@1.0.0/build/index.js"
  assert.equal "https://unpkg.com/foo@1.0.0/build/index.js", url

cdnSuite = ->
  test "CDN Resolver", [
    test "matches paths containing node_modules", testCdnMatch
    test "encodes dependency object", testCdnEncode
    test "decodes atlas URL", testCdnDecodeScoped
    test "decodes unscoped atlas URL", testCdnDecodeUnscoped
    test "resolves using URL Codex template", testCdnResolveScoped
    test "resolves unscoped using URL Codex template", testCdnResolveUnscoped
  ]

testLocalMatch = ->
  resolver = createLocalResolver()
  assert resolver.match
    source: "/root/.tempo/repos/foo/build/node/src/index.js"
    cwd: "/root/app"
  assert !resolver.match { source: "/other/foo/index.js", cwd: "/root/app" }

testLocalEncode = ->
  resolver = createLocalResolver()
  url = resolver.encode
    resolver: "local@central-park"
    module: { scope: "@scope", name: "foo", version: "1.0.0" }
    path: "/build/node/src/index.js"
  expected =
    "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
  assert.equal expected, url

testLocalDecodeScoped = ->
  resolver = createLocalResolver()
  url = "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
  assertDecodedModule ( resolver.decode url ),
    resolver: "local@central-park", scope: "@scope"
    name: "foo", version: "1.0.0", path: "/build/node/src/index.js"

testLocalDecodeUnscoped = ->
  resolver = createLocalResolver()
  url = "atlas://local@central-park/foo@1.0.0/build/node/src/index.js"
  assertDecodedModule ( resolver.decode url ),
    resolver: "local@central-park", scope: undefined
    name: "foo", version: "1.0.0", path: "/build/node/src/index.js"

testLocalResolve = ->
  resolver = createLocalResolver()
  target =
    "atlas://local@central-park/@scope/foo@1.0.0/build/node/src/index.js"
  url = resolver.resolve target
  assert typeof url == "string"

localSuite = ->
  test "Local Resolver", [
    test "matches configured deep glob patterns", testLocalMatch
    test "encodes dependency object", testLocalEncode
    test "decodes scoped atlas URL", testLocalDecodeScoped
    test "decodes unscoped atlas URL", testLocalDecodeUnscoped
    test "resolves to physical path", testLocalResolve
  ]

testNodePreset = ->
  keys = presets.node
  assert Array.isArray keys
  assert keys.includes "application"
  assert keys.includes "node"

testBrowserPreset = ->
  keys = presets.browser
  assert Array.isArray keys
  assert keys.includes "application"
  assert keys.some ( key ) -> key.startsWith "cdn"

presetsSuite = ->
  test "Resolver Presets", [
    test "Node preset exports keys", testNodePreset
    test "Browser preset exports keys", testBrowserPreset
  ]

export default -> [
  registrySuite()
  applicationSuite()
  nodeSuite()
  cdnSuite()
  localSuite()
  presetsSuite()
]