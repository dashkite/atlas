import semver from "semver"
import * as _ from "@dashkite/joy"
import { fetchJSON } from "../helpers"
import { Resource } from "./resource"

class WebResource extends Resource
  @create: (name, url) -> _.assign (new @), {name, url}
  load: -> @manifest = await fetchJSON @url

export { WebResource }
