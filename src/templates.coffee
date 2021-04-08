
jsdelivr =

  file: (reference) ->
    {name, version, paths} = reference
    "https://cdn.jsdelivr.net/npm/#{name}@#{version}/#{paths['.']}"

  scope: ({name}) ->
    "https://cdn.jsdelivr.net/npm/#{name}"

export {jsdelivr}
