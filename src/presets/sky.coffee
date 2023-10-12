import Generators from "#generators"
import CDN from "#generators/cdn"
import Relative from "#generators/relative"
import Sky from "#generators/sky"

Preset =

  apply: ({ provider, build, origin }) ->
    Generators.register [
      CDN.make { provider }
      Relative.make { build }
      Sky.make { origin }
    ]

export default Preset
export { Preset }

