import Path from "node:path"
import FS from "node:fs/promises"

Directory =

  contains: ( folder, path ) ->
    (( path.split Path.sep ).find ( component ) -> 
      component == folder )?

  within: ( directory, path ) ->
    !(( Path.relative directory, path ).startsWith "." )


export { Directory }
export default Directory