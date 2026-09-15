import { test } from "@dashkite/amen"
import assert from "@dashkite/assert"
import ModuleGraph from "../../src/categories/module-graph"
import Baseline from "../../src/functors/baseline"

export default ->
  [
    test "creates exact, module-scoped baseline mappings", ->
      moduleGraph = ModuleGraph.make()
      
      # Add source module
      ModuleGraph.addVertex moduleGraph, "atlas://app/src/index.js"
      # Add target module
      ModuleGraph.addVertex moduleGraph, "atlas://app/node_modules/maeve/index.js"
      
      # Add inter-module edge (inter edge)
      ModuleGraph.addEdge moduleGraph,
        source: "atlas://app/src/index.js"
        target: "atlas://app/node_modules/maeve/index.js"
        label: "maeve"
        type: "inter"
        
      # Add intra-module edge (intra edge) - should be ignored
      ModuleGraph.addVertex moduleGraph, "atlas://app/src/helper.js"
      ModuleGraph.addEdge moduleGraph,
        source: "atlas://app/src/index.js"
        target: "atlas://app/src/helper.js"
        label: "./helper.js"
        type: "intra"

      trie = Baseline.apply moduleGraph
      
      # Now verify the trie structure.
      # The root should have 'app' -> 'src' -> 'index.js'
      appNode = trie.children.get("app")
      assert appNode?, "expected app node"
      
      srcNode = appNode.children.get("src")
      assert srcNode?, "expected src node"
      
      indexNode = srcNode.children.get("index.js")
      assert indexNode?, "expected index.js node"
      
      # The binding should be in the exact source node (index.js)
      assert.equal indexNode.bindings.size, 1
      
      targetNode = indexNode.bindings.get("maeve")
      assert targetNode?, "expected maeve binding"
      
      # Target node should be the actual node in the trie for maeve/index.js
      assert.equal targetNode.segment, "index.js"
      
      # Check that intra edges were ignored
      assert !indexNode.bindings.has("./helper.js")
  ]
