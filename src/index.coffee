import Path from "node:path"
import * as Fn from "@dashkite/joy/function"
import * as It from "@dashkite/joy/iterable"

import analyze from "#helpers/analyze"
import Map from "#helpers/import-map"
import Generators from "./generators"

generate = ( entries, map ) ->
  map = if map? then Map.from map else Map.make()
  for await dependency from analyze entries
    Map.add map, 
      await Generators.apply { entries, dependency }
  map

export default { generate }
export { generate }
