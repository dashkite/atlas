import * as t from "@dashkite/genie"
import preset from "@dashkite/genie-presets"
import * as m from "@dashkite/masonry"

preset t

t.define "yaml", m.start [
  m.glob [ "{src,test}/**/*.yaml" ], "."
  m.copy "build/node"
]

t.after "build", [ "yaml" ]
