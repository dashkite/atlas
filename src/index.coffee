import Path from "node:path"

import analyze from "#helpers/analyze"
import Map from "#helpers/import-map"

generate = ( entries, map ) ->
  map = if map? then Map.from map else Map.make()
  for await dependency from analyze entries
    await Map.add map, dependency
  map

export default { generate }
export { generate }
