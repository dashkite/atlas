import * as _ from "@dashkite/joy"
import { error } from "../errors"

subpaths = ({name, version, manifest}) ->
  if _.isString manifest.exports
    ".": manifest.exports
  else
    if (manifest.exports["."])?
      manifest.exports
    else
      throw error "exports conditions", name, version

paths = ({name, version, manifest}) ->
  if manifest.exports?
    subpaths {name, version, manifest}
  else
    if (entry = (manifest.module ? manifest.browser))?
      ".": entry
    else if (entry = manifest.main)?
      # console.warn error "no exports", name, version
      ".": entry
    else
      throw error "no exports", name, version

export { paths }
