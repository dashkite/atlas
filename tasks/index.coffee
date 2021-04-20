import "coffeescript/register"
import p from "path"
import * as t from "@dashkite/genie"
import * as m from "@dashkite/masonry"
import {coffee} from "@dashkite/masonry/coffee"
import * as q from "panda-quill"
import YAML from "js-yaml"
import * as _ from "@dashkite/joy"

t.define "clean", -> m.rm "build"

t.define "yaml", m.start [
  m.glob [ "src/**/*.yaml" ], "."
  m.read
  m.copy p.join "build", "node"
]

t.define "build", [ "clean", "yaml" ], m.start [
  m.glob [ "{src,test}/**/*.coffee" ], "."
  m.read
  _.flow [
    m.tr coffee "node"
    m.extension ".js"
    m.write p.join "build", "node"
  ]
]

t.define "node:test", [ "build" ], ->
  m.exec "node", [
    "--enable-source-maps"
    "./build/node/test/index.js"
  ]

t.define "test", -> require "../test"
