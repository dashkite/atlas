import { Resource } from "./resource"
import { merge } from "./helpers"

mine = (resource) ->
  [resource.specifier]:
    Promise.all (for name, qualifier of manifest.dependencies
      Resource.create name, qualifier)

theirs = (resource) ->
  Promise.all (for name, qualifier of resource.dependencies
    dependencies name, qualifier)

dependencies = (name, qualifier) ->
  resource = await Resource.create name, qualifier
  merge [
    await mine _manifest
    (await theirs _manifest)...
  ]

export {
  dependencies
}
