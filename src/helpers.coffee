import fetch from "node-fetch"
import * as _ from "@dashkite/joy"

# merge for dictionaries of lists, where we want to combine lists
# corresponding to the same key
merge = (ax) ->
  rx = {}
  for a in ax
    for k, v of a
      rx[k] = if rx[k]?
        _.cat rx[k], v
      else
        v
  rx

fetchJSON = _.flow [ fetch, (response) -> response.json() ]

export {
  merge
  fetchJSON
}
