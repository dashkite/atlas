import TreeIndex from "../categories/tree-index"
import ComponentGraph from "../categories/component-graph"
import AtlasURL from "../url"

Resolver =
  apply: ( componentGraph, treeIndex ) ->
    bundle = new Map()
    paths = TreeIndex.getPaths treeIndex
    
    # Memoize directory resolution
    dirCache = new Map()
    
    getComponentPackageName = (component) ->
      modules = ComponentGraph.getModules componentGraph, component
      return "" if !modules? or modules.size == 0
      firstModule = Array.from(modules)[0]
      parsed = AtlasURL.parse firstModule
      parsed.package ? ""

    resolveDir = ( path, component ) ->
      cacheKey = "#{component}::#{JSON.stringify(path)}"
      return dirCache.get(cacheKey) if dirCache.has cacheKey
      
      pkgName = getComponentPackageName component
        
      if path.length == 0
        # If it's the root component, pkgName might be empty (for app urls).
        # Or if it's explicitly the entry point, it goes to root.
        bindings = TreeIndex.getBindings treeIndex, []
        boundLabel = null
        for [lbl, tgt] from bindings
          if tgt == component
            boundLabel = lbl
            break
            
        if boundLabel == component
          dir = ""
        else
          dir = "node_modules/#{pkgName}"
      else
        if pkgName == ""
          throw new Error "Nested dependency [#{component}] is missing a package specifier."
          
        parentComponent = path[path.length - 1]
        parentPath = path.slice 0, -1
        parentDir = resolveDir parentPath, parentComponent
        
        if parentDir == ""
          dir = "node_modules/#{pkgName}"
        else
          dir = "#{parentDir}/node_modules/#{pkgName}"
          
      dirCache.set cacheKey, dir
      dir

    # Process all bound components across all paths
    seenComponents = new Set()
    
    for path in paths
      bindings = TreeIndex.getBindings treeIndex, path
      
      for [label, component] from bindings
        # We process each component exactly once per physical location
        # A component can be bound in multiple paths if not hoisted,
        # but Node.js requires duplicated physical files in that case!
        
        physicalDir = resolveDir path, component
        
        modules = ComponentGraph.getModules componentGraph, component
        for moduleUrl from modules
          parsed = AtlasURL.parse moduleUrl
          
          # Compute file path within the bundle
          outputFile = if physicalDir == ""
            parsed.subpath
          else
            "#{physicalDir}/#{parsed.subpath}"
            
          bundle.set outputFile, moduleUrl

    bundle

export default Resolver
