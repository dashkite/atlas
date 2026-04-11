import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import XRL from "#helpers/xrl"

generators = []

register = generic name: "Generator.register"

generic register, Type.isObject, ( generator ) ->
  generators.unshift generator

generic register, Type.isArray, ( generators ) ->
  register generator for generator in generators

Generators =

  register: register

  default: 
    name: "default"
    matches: -> true
    apply: ( dependency ) ->
      scope: dependency.import.scope.source.path
      specifier: dependency.import.specifier
      target: dependency.source.path
    scope: ( dependency ) -> 
      dependency.source.path

  initialize: ->
    for generator in generators
      generator.initialize?()

  match: ( dependency ) ->
    ( generator ) -> generator.matches dependency

  find: ( dependency ) ->
    generators.find Generators.match dependency

  apply: ( dependency ) ->
    Generators
      .find dependency
      .apply dependency

  scope: ( dependency ) ->
    Generators
      .find dependency
      .scope dependency

register Generators.default

export { Generators }
export default Generators
