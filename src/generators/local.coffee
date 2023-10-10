import Path from "node:path"
import Directory from "#helpers/directory"
import XRL from "#helpers/xrl"
import { Specifier, Source } from "#helpers/dependency"

Local =

  make: ({ build }) ->

    url = ({ dependency }) ->
      XRL.Path.root do ->
        Path.relative build, dependency.source.path

    matches: ({ dependency }) ->
      !( Source.isRelative dependency ) &&
        !( Directory.contains "node_modules", 
          dependency.source.path )

    apply: ({ dependency }) ->

      if Specifier.isAlias dependency

        scope = XRL.Path.root()
        specifier = dependency.import.specifier

      else

        scope = XRL.Path.root do ->
          Path.relative build, 
            dependency.import.scope.source.path

        specifier = XRL.Path.join [ 
          scope
          dependency.import.specifier
        ]

      target = url { dependency } 

      { scope, specifier, target }

    scope: url


export { Local }
export default Local