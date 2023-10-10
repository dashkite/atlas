import Directory from "#helpers/directory"

Specifier =

  isRelative: ( dependency ) ->
    dependency.import.specifier.startsWith "."

  isAlias: ( dependency ) ->
    dependency.import.specifier.startsWith "#"

export { Specifier }

Source =

  isRelative: ({ source }) -> source.path.startsWith "."

  isExternal: ({ source }) -> source.path.startsWith ".."

  isInstalled: ({ source }) ->
    Directory.contains "node_modules", source.path


export { Source }