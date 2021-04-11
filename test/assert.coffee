import _assert from "assert/strict"
import * as _ from "@dashkite/joy"

assertions =
  kind: (a, b) -> _assert.equal true, _.isKind a, b
  type: (a, b) -> _assert.equal true, _.isType a, b

assert = new Proxy _assert,

  apply: (target, self, ax) -> target.equal true, ax[0]

  get: (target, name) -> assertions[name] ? target[name]

export default assert
