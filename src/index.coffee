import Path from "node:path"

import analyze from "#helpers/analyze"
import Map from "#helpers/import-map"
import resolve from "#helpers/import-map/resolve"
import Generators from "#generators"
import Local from "#generators/local"

generate = ( entries, map, options = {} ) ->
  Generators.initialize()
  map = if map? then Map.from map else Map.make()
  Map.optimize await Map.add map, analyze entries, options

export default { generate, Local, analyze, resolve, Map }
export { generate, Local, analyze, resolve, Map }
