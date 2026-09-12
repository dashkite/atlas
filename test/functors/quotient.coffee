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
      
      # Maeve component files
      ModuleGraph.addVertex moduleGraph, "file:///node_modules/maeve/index.js"
      ModuleGraph.addVertex moduleGraph, "file:///node_modules/maeve/lib.js"

      # App internal morphisms
      ModuleGraph.addEdge moduleGraph,
        source: "file:///app/index.js"
        target: "file:///app/helper.js"
        label: "./helper.js"
        type: "intra"

      ModuleGraph.addEdge moduleGraph,
        source: "file:///app/helper.js"
        target: "file:///app/utils.js"
        label: "./utils.js"
        type: "intra"

      # Maeve internal morphisms
      ModuleGraph.addEdge moduleGraph,
        source: "file:///node_modules/maeve/index.js"
        target: "file:///node_modules/maeve/lib.js"
        label: "./lib.js"
        type: "intra"

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
  ]
