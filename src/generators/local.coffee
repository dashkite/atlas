import Path from "node:path"
import XRL from "#helpers/xrl"
import { Specifier, Source } from "#helpers/dependency"

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
      ( scope?.module?.path == "." ) ||
        ( scope?.module?.path == root ) ||
        ! (( Source.isPublished scope ) || ( Source.isExternal scope ))

    isPhysicallyNested = ( dependency ) ->
      return false unless dependency?.import?.scope?
      importerPath = dependency.import.scope.module?.path
      sourcePath = dependency.source?.path
      return false unless importerPath? && sourcePath?
      return false if sourcePath.includes ".pnpm/"
      sourcePath.startsWith( "#{ importerPath }/node_modules/" ) ||
        ( sourcePath.includes( "node_modules/" ) && sourcePath.split(/\/node_modules\/|node_modules\//).length > 2 )

    getPackagePrefix = ( scope ) ->
      if isRoot scope
        "/"
      else
        pkgSegment = getPkgSegment scope?.module
        if isPhysicallyNested scope
          parentPrefix = getPackagePrefix scope.import.scope
          importerPkgSegment = getPkgSegment scope.import.scope?.module
          if importerPkgSegment != pkgSegment
            "#{ parentPrefix }node_modules/#{ pkgSegment }/"
          else
            parentPrefix
        else
          "/node_modules/#{ pkgSegment }/"

    getURL = ( dependency ) ->
      if isRoot dependency
        XRL.Path.root dependency.source.path
      else
        pkgPrefix = getPackagePrefix dependency
        relPath = Source.relative dependency
        "#{ pkgPrefix }#{ relPath }"

    initialize: ->

    matches: ( dependency ) -> true

    scope: ( scope ) ->
      getPackagePrefix scope

    apply: ( dependency ) ->
      do ({ scope, specifier, target } = {}) ->
        target = getURL dependency

        if isRoot dependency.import.scope
          scope = "/"
        else
          isSamePackage = ( dependency.module?.path? && dependency.module?.path == dependency.import.scope.module?.path ) ||
            ( Specifier.isRelative dependency ) || ( Specifier.isAlias dependency )

          if isSamePackage && ( Specifier.isRelative dependency ) && dependency.import.scope?.source?.path?
            importerURL = getURL dependency.import.scope
            importerDir = Path.dirname importerURL
            scope = if importerDir != "." && importerDir != "/"
              "#{ importerDir }/"
            else
              getPackagePrefix dependency.import.scope
          else
            scope = getPackagePrefix dependency.import.scope

        specifier = dependency.import.specifier

        { scope, specifier, target }

export { Local }
export default Local
