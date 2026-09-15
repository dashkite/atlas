import { Registry, Application, CDN, Local } from "../resolvers/index"

Registry.register "application", Application.make()
Registry.register "cdn@unpkg", CDN.make template: "https://unpkg.com/{scope?}/{versioned}/{path*}"
Registry.register "cdn@jsdelivr", CDN.make template: "https://cdn.jsdelivr.net/npm/{scope?}/{versioned}/{path*}"
Registry.register "cdn@esm", CDN.make template: "https://esm.sh/{scope?}/{versioned}/{path*}"
Registry.register "local@default", Local.make root: process.cwd()

export default ["application", "local@default", "cdn@unpkg"]
