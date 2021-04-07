import fetch from "node-fetch"
import * as _ from "@dashkite/joy"

fetchJSON = _.flow [ fetch, (response) -> response.json() ]

export {
  fetchJSON
}
