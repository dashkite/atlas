import Generators from "#generators"
import CDN from "#generators/cdn"
import Relative from "#generators/relative"
import Sky from "#generators/sky"

Preset =

  apply: ({ origin, build }) ->
    Generators.register [
      CDN.make "jsdelivr"
      Relative.make { build }
      Sky.make { origin }
    ]

export default Preset
export { Preset }

