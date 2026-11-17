import AJV from "ajv"

ajv = new AJV()

validate = ajv.compile
  anyOf: [
    {
      type: "string"
      minLength: 1
    }
    {
      type: "array"
      minItems: 1
      items:
        type: "string"
        minLength: 1
    }
  ]

normalize = ( entries ) ->
  if validate entries
    [ entries ].flat()
  else
    throw new Error (
      "Entries must be a non-empty string or array of non-empty strings"
    )

export default normalize
export { normalize }
