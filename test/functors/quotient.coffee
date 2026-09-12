import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"
import ComponentGraph from "../../src/categories/component-graph"
import Quotient from "../../src/functors/quotient"

export default ->
  [
    test "contracts intra-component edges into discrete components", ->
      moduleGraph = ModuleGraph.make()
      
      # App component files
      ModuleGraph.addVertex moduleGraph, "file:///app/index.js"
      ModuleGraph.addVertex moduleGraph, "file:///app/helper.js"
      ModuleGraph.addVertex moduleGraph, "file:///app/utils.js"

      ModuleGraph.setAttribute moduleGraph, "file:///app/index.js", "packageId", "app"
      ModuleGraph.setAttribute moduleGraph, "file:///app/helper.js", "packageId", "app"
      ModuleGraph.setAttribute moduleGraph, "file:///app/utils.js", "packageId", "app"
      
      # Maeve component files
      ModuleGraph.addVertex moduleGraph, "file:///node_modules/maeve/index.js"
      ModuleGraph.addVertex moduleGraph, "file:///node_modules/maeve/lib.js"

      ModuleGraph.setAttribute moduleGraph, "file:///node_modules/maeve/index.js", "packageId", "maeve"
      ModuleGraph.setAttribute moduleGraph, "file:///node_modules/maeve/lib.js", "packageId", "maeve"

      # Inter-component morphisms
      ModuleGraph.addEdge moduleGraph,
        source: "file:///app/index.js"
        target: "file:///node_modules/maeve/index.js"
        label: "maeve"
        type: "inter"

      componentGraph = Quotient.apply moduleGraph
      
      # Assert the components are correct
      vertices = ComponentGraph.getVertices componentGraph
      assert.equal vertices.size, 2 # Two discrete components

      # Find the components containing specific files to map our IDs
      appComponentId = Array.from(vertices).find (id) ->
        ComponentGraph.getModules(componentGraph, id).has "file:///app/index.js"
      
      maeveComponentId = Array.from(vertices).find (id) ->
        ComponentGraph.getModules(componentGraph, id).has "file:///node_modules/maeve/index.js"

      assert appComponentId?
      assert maeveComponentId?

      # Check app component contains all 3 files
      appModules = ComponentGraph.getModules componentGraph, appComponentId
      assert.equal appModules.size, 3
      assert appModules.has "file:///app/helper.js"
      assert appModules.has "file:///app/utils.js"

      # Check inter-component edges are properly translated
      edges = ComponentGraph.getEdges componentGraph
      assert.equal edges.length, 1
      assert.equal edges[0].source, appComponentId
      assert.equal edges[0].target, maeveComponentId
      assert.equal edges[0].label, "maeve"

    test "contracts disjoint entry points of the same package into a single component", ->
      moduleGraph = ModuleGraph.make()

      # Assume these were marked by `ingest` with a shared package attribute
      ModuleGraph.addVertex moduleGraph, "atlas://npm/@dashkite/maeve@1.0.0/build/node/src/common.js"
      ModuleGraph.addVertex moduleGraph, "atlas://npm/@dashkite/maeve@1.0.0/build/node/src/sublime/index.js"
      ModuleGraph.addVertex moduleGraph, "atlas://local/@dashkite/enchant@2.0.0/build/node/src/index.js"

      # Explicitly set the subgraph (package) identities
      ModuleGraph.setAttribute moduleGraph, "atlas://npm/@dashkite/maeve@1.0.0/build/node/src/common.js", "packageId", "atlas://npm/@dashkite/maeve@1.0.0"
      ModuleGraph.setAttribute moduleGraph, "atlas://npm/@dashkite/maeve@1.0.0/build/node/src/sublime/index.js", "packageId", "atlas://npm/@dashkite/maeve@1.0.0"
      ModuleGraph.setAttribute moduleGraph, "atlas://local/@dashkite/enchant@2.0.0/build/node/src/index.js", "packageId", "atlas://local/@dashkite/enchant@2.0.0"

      # Enchant imports both independent entry points of Maeve
      ModuleGraph.addEdge moduleGraph,
        source: "atlas://local/@dashkite/enchant@2.0.0/build/node/src/index.js"
        target: "atlas://npm/@dashkite/maeve@1.0.0/build/node/src/common.js"
        label: "@dashkite/maeve/common"
        type: "inter"

      ModuleGraph.addEdge moduleGraph,
        source: "atlas://local/@dashkite/enchant@2.0.0/build/node/src/index.js"
        target: "atlas://npm/@dashkite/maeve@1.0.0/build/node/src/sublime/index.js"
        label: "@dashkite/maeve/sublime"
        type: "inter"

      # Notice there are NO intra-edges between common.js and sublime/index.js.
      # They are entirely disjoint from a relative import perspective.

      componentGraph = Quotient.apply moduleGraph

      vertices = ComponentGraph.getVertices componentGraph
      # Enchant should be 1 component, Maeve should be exactly 1 component!
      assert.equal vertices.size, 2, "Expected disjoint entry points to be collapsed into a single package component vertex"
  ]
