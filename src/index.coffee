import bundle from "./bundle"
import analyze from "./helpers/analyze"
import ingest from "./ingest"
import ModuleGraph from "./categories/module-graph"
import ComponentGraph from "./categories/component-graph"
import TreeIndex from "./categories/tree-index"
import Path from "./categories/path"
import Quotient from "./functors/quotient"
import Compiler from "./functors/compiler"
import Resolver from "./functors/resolver"
import AtlasURL from "./url"
import Resolvers, { App, NPM, Metarepo } from "./resolvers"

# For ImportMaps, generate could be used. Right now it just returns the tree logic.
generate = ( entries, map, options = {} ) ->
  # Placeholder for import map generation which is simpler and relies on the TreeIndex directly
  deps = analyze entries, options
  moduleGraph = await ingest deps, options
  componentGraph = Quotient.apply moduleGraph
  treeIndex = Compiler.apply componentGraph, options
  
  # Wait, the legacy generator returned an object with imports and scopes.
  # If we need the legacy format right now, we can adapt it or just leave it for the next phase.
  {}

export default {
  generate
  bundle
  analyze
  ingest
  ModuleGraph
  ComponentGraph
  TreeIndex
  Path
  Quotient
  Compiler
  Resolver
  AtlasURL
  Resolvers
  App
  NPM
  Metarepo
}

export {
  generate
  bundle
  analyze
  ingest
  ModuleGraph
  ComponentGraph
  TreeIndex
  Path
  Quotient
  Compiler
  Resolver
  AtlasURL
  Resolvers
  App
  NPM
  Metarepo
}
