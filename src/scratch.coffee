# lock = (dx) ->
#   rx = {}
#   for name, spec of dx
#     p = await manifest name, spec
#     rx[name] = p.version
#   rx
#
# subpaths = (p) ->
#   if p.exports?
#     if _.isString p.exports
#       [p.name]: p.exports
#     else
#       console.warn "#{p.name}: export subpaths are not yet supported"
#       {}
#   else
#     [p.name]: p.module ? p.main ? "index.js"
#
#
# pathToURL = (base, path) -> "#{base}/#{path}"
#
# pathsToURLs = (base, dx) ->
#   rx = {}
#   for name, path of dx
#     rx[name] = pathToURL base, path
#   rx
#
# scope = (dx) ->
#   rx = {}
#   for name, version of dx
#     u = "#{_scope}#{name}@#{version}"
#     p = await manifest name, version
#     _.assign rx, pathsToURLs u, subpaths p
#   rx
#
# imports = _.flow [
#   lock
#   scope
# ]
#
# expand = _.flow [
#   (dx) -> (dependencies name, spec) for name, spec of dx
#   (dx) -> Promise.all dx
#   (dx) -> _.merge dx...
#   imports
# ]
#
# generate = (dx) ->
#   imports: await imports dx
#   scopes:
#     [(new URL _scope).origin]: await expand dx

# _scope = "https://cdn.jsdelivr.net/npm/"
_scope = "https://ga.jspm.io/npm:"

log = _.tee (context) -> console.log context
  # console.log JSON.stringify await generate
  #   "@dashkite/carbon": undefined
  #   "@dashkite/quark": undefined
  #   # "@dashkite/joy": "file:../joy"
