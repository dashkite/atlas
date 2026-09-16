import { Registry, Application, CDN, Local } from "../resolvers/index"

Registry.register "application", Application.make()

Registry.register "cdn@unpkg", CDN.make template: (descriptor) ->
  if descriptor.module.scope
    "https://unpkg.com/{scope}/{versioned}/{path*}"
  else
    "https://unpkg.com/{versioned}/{path*}"

Registry.register "cdn@jsdelivr", CDN.make template: (descriptor) ->
  if descriptor.module.scope
    "https://cdn.jsdelivr.net/npm/{scope}/{versioned}/{path*}"
  else
    "https://cdn.jsdelivr.net/npm/{versioned}/{path*}"

Registry.register "cdn@esm", CDN.make template: (descriptor) ->
  if descriptor.module.scope
    "https://esm.sh/{scope}/{versioned}/{path*}"
  else
    "https://esm.sh/{versioned}/{path*}"

Registry.register "local@default", Local.make root: process.cwd()

export default ["application", "local@default", "cdn@unpkg"]
