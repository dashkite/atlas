import { map } from "./map"


do ->
  try
    console.log JSON.stringify await map
      # "@dashkite/quark": "latest"
      # "@dashkite/carbon": "latest"
      "@dashkite/joy": "file:../joy"
  catch error
    console.error error
