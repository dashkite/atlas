import Path from "node:path"

import analyze from "#helpers/analyze"
import Map from "#helpers/import-map"

generate = ( entries, map ) ->
  map = if map? then Map.from map else Map.make()
  Map.add map, analyze entries

export default { generate }
export { generate }
