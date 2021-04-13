import * as _ from "@dashkite/joy"
import * as $ from "../src"

e1 = _.assign (new $.RegistryReference),
  name: "e"
  range: "^1.0.0"
  manifest:
    name: "e"
    version: "1.0.0"
    exports:
      ".": "./build/import/src/z.js"
      "./*": "./build/import/src/*.js"
  files: [
    "./build/import/src/x.js"
    "./build/import/src/y/z.js"
  ]
  dependencies: new Set

e2 = _.assign (new $.RegistryReference),
  name: "e"
  range: "^1.0.0"
  manifest:
    name: "e"
    version: "1.1.0"
    exports:
      ".": "./build/import/src/z.js"
      "./*": "./build/import/src/*.js"
  files: [
    "./build/import/src/x.js"
    "./build/import/src/y/z.js"
  ]
  dependencies: new Set

d1 = _.assign (new $.RegistryReference),
  name: "d"
  range: "^1.0.0"
  manifest:
    name: "d"
    version: "1.0.0"
    exports:
      ".": "./build/import/src/z.js"
      "./*": "./build/import/src/*.js"
  files: [
    "./build/import/src/x.js"
    "./build/import/src/y/z.js"
  ]
  dependencies: new Set [ e1 ]

d2 = _.assign (new $.RegistryReference),
  name: "d"
  range: "^2.0.0"
  manifest:
    name: "d"
    version: "2.0.0"
    exports:
      ".": "./build/import/src/z.js"
      "./*": "./build/import/src/*.js"
  files: [
    "./build/import/src/x.js"
    "./build/import/src/y/z.js"
  ]
  dependencies: new Set [ e2 ]

c = _.assign (new $.RegistryReference),
  name: "c"
  manifest:
    name: "c"
    version: "1.0.0"
    exports:
      ".": "./build/import/src/z.js"
      "./*": "./build/import/src/*.js"
  files: [
    "./build/import/src/x.js"
    "./build/import/src/y/z.js"
  ]
  dependencies: new Set [ d2 ]

b = _.assign (new $.RegistryReference),
  name: "b"
  manifest:
    name: "b"
    version: "1.0.0"
    exports:
      ".": "./build/import/src/z.js"
      "./*": "./build/import/src/*.js"
      "#z": "./build/import/local/z.js"
      "#local/*": "./build/import/local/*.js"

  files: [
    "./build/import/src/x.js"
    "./build/import/src/y/z.js"
    "./build/import/local/x.js"
    "./build/import/local/y/z.js"
  ]
  dependencies: new Set [ c, d1 ]

a = _.assign (new $.RegistryReference),
  name: "a"
  manifest:
    name: "a"
    version: "1.0.0"
    exports:
      ".": "./build/import/src/z.js"
      "./*": "./build/import/src/*.js"
  files: [
    "./build/import/src/x.js"
    "./build/import/src/y/z.js"
  ]
  dependencies: new Set [ b ]

Fixtures = { a, b, c, d1, d2, e1, e2 }

export default Fixtures
