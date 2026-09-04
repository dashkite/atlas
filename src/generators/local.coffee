import Path from "node:path"
import Directory from "#helpers/directory"
import XRL from "#helpers/xrl"
import { Specifier, Source } from "#helpers/dependency"
import Module from "#helpers/module"
import Generators from "#generators"

Local =
  name: "local"

  make: ({ root = ".", cwd } = {}) ->
    root = cwd ? root

    getPkgSegment = ( module ) ->
      name = module?.specifier ? module?.name
      version = module?.version
      if version? && version != ""
        "#{ name }@#{ version }"
      else
        name

    isRoot = ( scope ) ->
      ( scope.module?.path == "." ) ||
        ( scope.module?.path == root ) ||
        ! (( Source.isPublished scope ) || ( Source.isExternal scope ))

    getScope = ( scope ) ->
      if isRoot scope
        "/"
      else
        pkgSegment = getPkgSegment scope.module
        if scope.import?.scope? && !isRoot( scope.import.scope )
          parentScope = await getScope scope.import.scope
          importerPkgSegment = getPkgSegment scope.import.scope.module
          if importerPkgSegment != pkgSegment
            "#{ parentScope }node_modules/#{ pkgSegment }/"
          else
            parentScope
        else
          "/node_modules/#{ pkgSegment }/"

    initialize: ->

    matches: ( dependency ) -> true

    scope: ( scope ) ->
      await getScope scope

    apply: ( dependency ) ->
      do ({ scope, specifier, target } = {}) ->
        parentScope = await getScope dependency.import.scope

        # Case 1: Dependency is within root application (and not in node_modules or external)
        isLocal = ( dependency.module?.path == "." ) ||
           ( dependency.module?.path == root ) ||
           ! (( Source.isPublished dependency ) || ( Source.isExternal dependency ))

        if isLocal

          scope = "/"
          specifier = dependency.import.specifier
          target = XRL.Path.root dependency.source.path

        # Case 2: Dependency is in a package (node_modules or external)
        else
          relPath = Source.relative dependency
          pkgSegment = getPkgSegment dependency.module
          isSamePackage = ( dependency.module?.path? && dependency.module?.path == dependency.import.scope.module?.path ) ||
            ( Specifier.isRelative dependency ) || ( Specifier.isAlias dependency )

          if isSamePackage
            if ( Specifier.isRelative dependency ) && dependency.import.scope?.source?.path?
              importerRelPath = Source.relative dependency.import.scope
              importerDir = Path.dirname importerRelPath
              scope = if importerDir != "." && importerDir != ""
                "#{ parentScope }#{ importerDir }/"
              else
                parentScope
            else
              scope = parentScope

            specifier = dependency.import.specifier
            target = "#{ parentScope }#{ relPath }"
          else
            targetScope = await getScope dependency

            scope = parentScope
            specifier = dependency.import.specifier
            target = "#{ targetScope }#{ relPath }"

        { scope, specifier, target }

export { Local }
export default Local
