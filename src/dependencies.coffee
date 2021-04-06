import { Resource } from "./resource"
import { merge } from "./helpers"

mine = (resource) ->
  [resource.specifier]:
    await Promise.all (for name, qualifier of resource.dependencies
      Resource.create name, qualifier)

theirs = (resource) ->
  Promise.all (for name, qualifier of resource.dependencies
    dependencies name, qualifier)

dependencies = (name, qualifier) ->
  resource = await Resource.create name, qualifier
  merge [
    await mine resource
    (await theirs resource)...
  ]

export {
  dependencies
}
