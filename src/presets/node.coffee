import { Registry, Application, Node, Local } from "../resolvers/index"

Registry.register "application", Application.make()
Registry.register "node", Node.make()
Registry.register "local@default", Local.make root: process.cwd()

export default ["application", "local@default", "node"]
