import Path from "node:path"
import Zephyr from "@dashkite/zephyr"
import XRL from "#helpers/xrl"
import { Specifier, Source } from "#helpers/dependency"

getHashes = ({ module }) ->
  Zephyr.read Path.join module.path, ".sky", "hashes.yaml"

getHash = ({ module, source }) ->
  do ({ path, hashes } = {}) ->    
    if ( hashes = await getHashes { module } )?
      path = Source.relative { source, module }
      hashes[ path ] ?
        throw new Error "No hash for [ #{ path }]"
    else
      throw new Error "No hashes found for module at 
        [ #{ module.path } ]"

getModuleURL = ({ origin, dependency }) ->
  do ({ scope, name } = dependency.module ) ->
    if scope?
      XRL.join [
        origin
        "@#{ scope }"
        name
      ]
    else
      XRL.join origin, name

getURL = ({ origin, dependency }) ->
  do ({ hash, base, path } = {}) ->
    hash = await getHash dependency
    base = getModuleURL { origin, dependency }
    path = Source.relative dependency
    XRL.join [ base, hash, path ]
      
Sky =

  make: ({ origin }) ->

    _getURL = ( dependency ) ->
      getURL { origin, dependency }

    matches: ( dependency ) -> 
      ( Source.isExternal dependency ) &&
        !( Source.isInstalled dependency )
      

    apply: ( dependency ) ->

      do ({ scope, specifier, target } = {}) ->

        if Specifier.isRelative dependency

          scope = await getURL {
            origin
            dependency: dependency.import.scope 
          }

          specifier = XRL.join [
            XRL.pop scope
            dependency.import.specifier
          ]

        else

          specifier = dependency.import.specifier

        target = await _getURL dependency

        { scope, specifier, target }

    scope: _getURL

export { Sky }
export default Sky