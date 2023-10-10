import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"

generators = []

register = generic name: "Generator.register"

generic register, Type.isObject, ( generator ) ->
  generators.unshift generator

generic register, Type.isArray, ( generators ) ->
  register generator for generator in generators

Generators =

  register: register

  default: 
    match: -> true
    apply: ({ dependency }) ->
      specifier: dependency.import.specifier
      url: dependency.source.path
    scope: ({ dependency }) ->
      dependency.source.path

  match: ( context ) ->
    ( generator ) -> generator.matches context

  find: ( context ) ->
    generators.find Generators.match context

  apply: ( context ) ->
    Generators
      .find context
      .apply context

  scope: ( context ) ->
    Generators
      .find context
      .scope context

register Generators.default

export { Generators }
export default Generators