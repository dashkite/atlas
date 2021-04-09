import fetch from "node-fetch"
import * as _ from "@dashkite/joy"
import { error } from "./errors"

fetchJSON = _.flow [
  fetch
  # TODO fix client issue in mercury
  (response) ->
    if response.status == 200
      response.json()
    else
      throw error "unexpected response", response.url, response.status
]

export {
  fetchJSON
}
