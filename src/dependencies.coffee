import {
  specifier
  resolve
  manifest
} from "./manifest"
import { merge } from "./helpers"

context = (name, qualifier) ->
  {name, qualifier, version: await resolve name, qualifier}

mine = (manifest) ->
  [specifier manifest.name, manifest.version]:
    for name, qualifier of manifest.dependencies
      await context name, qualifier

theirs = (manifest) ->
  Promise.all (for name, qualifier of manifest.dependencies
    dependencies name, qualifier)

dependencies = (name, qualifier) ->
  _manifest = await manifest name, qualifier
  merge [
    await mine _manifest
    (await theirs _manifest)...
  ]

export {
  context
  dependencies
}
