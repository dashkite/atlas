import Resolvers from "../resolvers/index"
{ Local, CDN, Application } = Resolvers

export default ( config = {} ) ->
  [
    Local.make config.local
    CDN.make config.cdn
    Application.make config.application
  ]
