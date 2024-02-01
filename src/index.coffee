import Path from "node:path"

import analyze from "#helpers/analyze"
import Map from "#helpers/import-map"
import Generators from "#generators"

generate = ( entries, map ) ->
  Generators.initialize()
  map = if map? then Map.from map else Map.make()
  Map.compact await Map.add map, analyze entries

export default { generate }
export { generate }
