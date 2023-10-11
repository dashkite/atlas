import Path from "node:path"
import Directory from "#helpers/directory"
import XRL from "#helpers/xrl"
import { Specifier, Source } from "#helpers/dependency"

Local =

  make: ({ build }) ->

    getURL = ( dependency ) ->
      XRL.Path.root Path.relative build, dependency.source.path

    matches: ( dependency ) ->
      Directory.within build, dependency.source.path

    apply: ( dependency ) ->

      do ({ scope, specifier, target } = {}) ->

        if Specifier.isAlias dependency

          scope = XRL.Path.root()
          specifier = dependency.import.specifier

        else

          scope = XRL.Path.root do ->
            Path.relative build, 
              dependency.import.scope.source.path

          specifier = XRL.Path.join [ 
            XRL.pop scope
            dependency.import.specifier
          ]

        target = getURL dependency

        { scope, specifier, target }

    scope: getURL


export { Local }
export default Local