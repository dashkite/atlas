import Path from "node:path"
import * as Fn from "@dashkite/joy/function"
import * as It from "@dashkite/joy/iterable"

import { analyze } from "./helpers/analyze"
import { Build } from "./helpers/build"
import { Resource } from "./helpers/resource"
import { ImportMap } from "./helpers/import-map"

generate = ( entries, map ) ->

  await do Fn.flow [
    -> analyze entries
    It.map Build.decorator
    It.map Resource.decorator entries
    It.reduce ImportMap.add,
      if map then ImportMap.from map else ImportMap.make()

  ]

export { generate }
