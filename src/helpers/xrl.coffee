import $Path from "node:path"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"

# TODO fix this in Joy
# https://github.com/dashkite/joy/issues/14

reduce = ( acc, initial, items ) ->
  items.reduce (( result, item ) -> acc result, item ), initial

isPath = ( value ) ->
  ( Type.isString value ) &&
    (( value.startsWith "/" ) ||
      ( value.startsWith ".") ||
      !( isAbsolute value ))

isAbsolute = ( value ) ->
  ( Type.isString value ) && ( /^[a-z]+:/.test value )

Path =

  root: ( path ) -> "/#{ path }"

  relative: ( base, path ) ->
    $Path.posix.relative base, path

  join: do ({ join } = {}) ->
    
    join = generic name: "XRL.Path.join"
    
    generic join, Type.isArray, ([ first, rest... ]) ->
      reduce join, first, rest
    
    generic join, isPath, isPath, $Path.posix.join
    
    join

XRL =

  Path: Path

  isPath: isPath

  isAbsolute: isAbsolute

  join: do ({ join } = {}) ->

    join = generic 
      name: "XRL.join"
      default: ( args... ) -> console.log args
    
    generic join, Type.isArray, ([ first, rest... ]) ->
      reduce join, first, rest
    
    generic join, isAbsolute, isPath, ( base, rest ) ->
      ( new URL rest, base ).toString()

    generic join, isPath, isPath, Path.join
    
    join

  pop: do ({ pop } = {}) ->
    
    pop = generic name: "XRL.pop"

    generic pop, isPath, $Path.posix.dirname

    generic pop, isAbsolute, ( url ) ->
      parsed = new URL url
      parsed.pathname = pop parsed.pathname
      parsed.toString()

    pop

export { XRL }
export default XRL