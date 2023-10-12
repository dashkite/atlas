import Path from "node:path"
import Directory from "#helpers/directory"
import XRL from "#helpers/xrl"
import { Specifier, Source } from "#helpers/dependency"

Relative =

  make: ({ build }) ->

    getURL = ( dependency ) ->
      XRL.Path.root Path.relative build, 
        dependency.source.path

    matches: ( dependency ) ->
      Directory.within build, dependency.source.path

    apply: ( dependency ) ->

      do ({ scope, specifier, target } = {}) ->

        scope = XRL.Path.root do ->
          Path.relative build, 
            dependency.import.scope.source.path

        specifier = do ->

          if Specifier.isAlias dependency
            dependency.import.specifier
          else
            XRL.Path.join [ 
              XRL.pop scope
              dependency.import.specifier
            ]

        target = getURL dependency

        { scope, specifier, target }

    scope: getURL


export { Relative }
export default Relative