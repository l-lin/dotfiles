local helpers = require("functions.lang.mermaid.graph_renderer.spec_helper")
local geometry = require("functions.lang.mermaid.graph_renderer.geometry")
local route = require("functions.lang.mermaid.graph_renderer.route")

describe("mermaid.graph_renderer.route", function()
  it(
    "GIVEN nested subgraphs and outgoing edges WHEN querying helpers THEN direction membership and children are derived from layout state",
    function()
      local given_root = { name = "Root", shape = "rectangle", grid_coord = { x = 0, y = 0 } }
      local given_parent = { name = "Parent", shape = "rectangle", grid_coord = { x = 0, y = 4 } }
      local given_child = { name = "Child", shape = "rectangle", grid_coord = { x = 4, y = 4 } }
      local given_parent_subgraph = {
        id = "ParentGroup",
        parent = nil,
        direction = nil,
        depth = 0,
        nodes = { given_parent, given_child },
      }
      local given_child_subgraph = {
        id = "ChildGroup",
        parent = given_parent_subgraph,
        direction = "LR",
        depth = 1,
        nodes = { given_child },
      }
      given_parent_subgraph.children = { given_child_subgraph }

      local actual_children = route.get_children({
        edges = {
          { from = given_root, to = given_parent },
          { from = given_root, to = given_child },
        },
        innermost_subgraph_by_node = {
          [given_parent] = given_parent_subgraph,
          [given_child] = given_child_subgraph,
        },
        config = { graph_direction = "TD" },
      }, given_root)
      local expected_children = { given_parent, given_child }

      assert.are.same(expected_children, actual_children)
      assert.are.equal(
        "TD",
        route.get_effective_direction({
          innermost_subgraph_by_node = { [given_parent] = given_parent_subgraph },
          config = { graph_direction = "TD" },
        }, given_parent)
      )
      assert.are.equal(
        "LR",
        route.get_effective_direction({
          innermost_subgraph_by_node = { [given_child] = given_child_subgraph },
          config = { graph_direction = "TD" },
        }, given_child)
      )
      assert.is_false(route.node_in_subgraph({ innermost_subgraph_by_node = {} }, given_root))
      assert.is_true(
        route.node_in_subgraph({ innermost_subgraph_by_node = { [given_child] = given_child_subgraph } }, given_child)
      )
    end
  )

  it(
    "GIVEN a node inside an inheriting subgraph and no outgoing edges WHEN querying helpers THEN it inherits the nearest ancestor direction and has no children",
    function()
      local given_node = { name = "Nested", shape = "rectangle", grid_coord = { x = 0, y = 0 } }
      local given_root_subgraph = {
        id = "RootGroup",
        parent = nil,
        direction = "LR",
        depth = 0,
        nodes = { given_node },
      }
      local given_child_subgraph = {
        id = "ChildGroup",
        parent = given_root_subgraph,
        direction = nil,
        depth = 1,
        nodes = { given_node },
      }

      local actual_direction = route.get_effective_direction({
        innermost_subgraph_by_node = { [given_node] = given_child_subgraph },
        config = { graph_direction = "TD" },
      }, given_node)
      local actual_children = route.get_children({ edges = {} }, given_node)

      assert.are.equal("LR", actual_direction)
      assert.are.same({}, actual_children)
    end
  )

  it(
    "GIVEN two placed nodes with a labelled edge WHEN preparing routes THEN the path and label segment are materialized",
    function()
      local actual = helpers.given_route_graph()

      route.prepare_edge_routes(actual)

      local actual_edge = actual.edges[1]
      local expected_path = {
        { x = 1, y = 2 },
        { x = 1, y = 4 },
      }

      assert.are.same(expected_path, actual_edge.path)
      assert.are.same(expected_path, actual_edge.label_line)
      assert.are.same(geometry.Directions.down, actual_edge.start_dir)
      assert.are.same(geometry.Directions.up, actual_edge.end_dir)
      assert.are.equal(5, actual.row_height[3])
      assert.are.equal(4, actual.column_width[1])
    end
  )

  it(
    "GIVEN two horizontally placed nodes in an LR graph WHEN preparing routes THEN the path runs left-to-right",
    function()
      local given_config = helpers.given_layout_config("LR")
      local given_from = helpers.given_layout_node("A", "A", "rectangle", { x = 0, y = 0 }, given_config)
      local given_to = helpers.given_layout_node("B", "B", "rectangle", { x = 4, y = 0 }, given_config)
      local actual = helpers.given_layout_graph(
        { given_from, given_to },
        { helpers.given_layout_edge(given_from, given_to, "go") },
        "LR"
      )

      route.prepare_edge_routes(actual)

      local actual_edge = actual.edges[1]
      local expected_path = {
        { x = 2, y = 1 },
        { x = 4, y = 1 },
      }

      assert.are.same(expected_path, actual_edge.path)
      assert.are.same(geometry.Directions.right, actual_edge.start_dir)
      assert.are.same(geometry.Directions.left, actual_edge.end_dir)
    end
  )

  it("GIVEN an unlabelled edge WHEN preparing routes THEN no label segment is reserved", function()
    local given_graph = helpers.given_route_graph()
    given_graph.edges[1].text = ""

    route.prepare_edge_routes(given_graph)

    assert.are.same({}, given_graph.edges[1].label_line)
    assert.is_nil(given_graph.edges[1].has_branch_label)
  end)

  it(
    "GIVEN a labelled edge from a branching pseudostate WHEN preparing routes THEN it becomes a branch label instead of an inline segment",
    function()
      local given_config = helpers.given_layout_config("TD")
      local given_from = helpers.given_layout_node("Route", "", "state-choice", { x = 0, y = 0 }, given_config)
      local given_to = helpers.given_layout_node("Target", "Target", "rectangle", { x = 0, y = 4 }, given_config)
      local actual = helpers.given_layout_graph(
        { given_from, given_to },
        { helpers.given_layout_edge(given_from, given_to, "yes") },
        "TD"
      )

      route.prepare_edge_routes(actual)

      assert.is_true(actual.edges[1].has_branch_label)
      assert.are.same({}, actual.edges[1].label_line)
    end
  )
end)
