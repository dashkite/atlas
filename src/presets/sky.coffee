import Generators from "#generators"
import CDN from "#generators/cdn"
import Local from "#generators/local"
import Sky from "#generators/sky"

Preset =

  apply: ({ origin, build }) ->
    Generators.register [
      CDN.make "jsdelivr"
      Local.make { build }
      Sky.make { origin }
    ]

export default Preset
export { Preset }

