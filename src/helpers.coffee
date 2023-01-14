import Fetch from "make-fetch-happen"
import * as _ from "@dashkite/joy"
import { error } from "./errors"

fetch = Fetch.defaults
  cachePath: "./.atlas"
  cache: "force-cache"

fetchJSON = _.flow [
  fetch
  (response) ->
    if response.status == 200
      response.json()
    else
      throw error "unexpected response", response.url, response.status
]

export {
  fetchJSON
}
