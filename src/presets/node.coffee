import Resolvers from "../resolvers/index"
{ Local, NPM, Application } = Resolvers

export default ( config = {} ) ->
  [
    Local.make config.local
    NPM.make config.npm
    Application.make config.application
  ]
