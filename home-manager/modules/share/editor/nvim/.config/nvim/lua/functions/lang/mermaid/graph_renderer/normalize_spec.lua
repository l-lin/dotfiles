local helpers = require("functions.lang.mermaid.graph_renderer.spec_helper")
local normalize = require("functions.lang.mermaid.graph_renderer.normalize")

describe("mermaid.graph_renderer.normalize", function()
  it(
    "GIVEN composite-state edges and nested regions WHEN normalizing THEN edges notes and directions are resolved for rendering",
    function()
      local given_region = helpers.given_parsed_subgraph("PackingRegion", "Packing", "region", { "Packing" }, {}, "BT")
      local given_subgraph = helpers.given_parsed_subgraph(
        "Fulfilment",
        "Fulfilment",
        "composite",
        { "Start", "Packing", "Done" },
        { given_region },
        "RL"
      )

      local actual = normalize.from_parsed({
        direction = "RL",
        nodes = {
          Outside = helpers.given_parsed_node("Outside", "Outside", "rectangle"),
          Start = helpers.given_parsed_node("Start", "", "state-start"),
          Packing = helpers.given_parsed_node("Packing", "Packing", "rectangle"),
          Done = helpers.given_parsed_node("Done", "", "state-end"),
        },
        node_order = { "Outside", "Start", "Packing", "Done" },
        edges = {
          {
            source = "Outside",
            target = "Fulfilment",
            label = "enter",
            style = "dotted",
            has_arrow_start = false,
            has_arrow_end = true,
          },
          {
            source = "Fulfilment",
            target = "Outside",
            label = "leave",
            style = "solid",
            has_arrow_start = false,
            has_arrow_end = true,
          },
          {
            source = "Missing",
            target = "Outside",
            label = "ignored",
            style = "solid",
            has_arrow_start = false,
            has_arrow_end = true,
          },
        },
        subgraphs = { given_subgraph },
        notes = {
          { state_id = "Outside", position = "right", text = "external note" },
          { state_id = "Ghost", position = "left", text = "ignored note" },
        },
        class_defs = {},
        class_assignments = {},
        node_styles = {},
        link_styles = {},
        warnings = {},
      })

      local actual_names = {}
      for _, node in ipairs(actual.subgraph_by_id.Fulfilment.nodes) do
        actual_names[#actual_names + 1] = node.name
      end

      assert.are.equal("LR", actual.config.graph_direction)
      assert.are.equal("RL", actual.parsed_direction)
      assert.are.equal(2, #actual.edges)
      assert.are.equal("Outside", actual.edges[1].from.name)
      assert.are.equal("Start", actual.edges[1].to.name)
      assert.are.equal("Fulfilment", actual.edges[1].target_composite_id)
      assert.are.equal("Done", actual.edges[2].from.name)
      assert.are.equal("Outside", actual.edges[2].to.name)
      assert.are.equal("Fulfilment", actual.edges[2].source_composite_id)
      assert.are.equal("LR", actual.subgraph_by_id.Fulfilment.direction)
      assert.are.equal("TD", actual.subgraph_by_id.PackingRegion.direction)
      assert.are.same({ "Start", "Packing", "Done" }, actual_names)
      assert.are.equal("PackingRegion", actual.innermost_subgraph_by_node[actual.nodes[3]].id)
      assert.are.same({ node = actual.nodes[1], position = "right", text = "external note" }, actual.notes[1])
      assert.is_true(
        normalize.is_ancestor_or_self(actual.subgraph_by_id.Fulfilment, actual.subgraph_by_id.PackingRegion)
      )
      assert.is_false(
        normalize.is_ancestor_or_self(actual.subgraph_by_id.PackingRegion, actual.subgraph_by_id.Fulfilment)
      )
    end
  )

  it(
    "GIVEN an empty parsed graph with nil direction WHEN normalizing THEN it defaults to a top-down empty renderer graph",
    function()
      local actual = normalize.from_parsed(helpers.given_empty_parsed_graph(nil))

      assert.are.same({}, actual.nodes)
      assert.are.same({}, actual.edges)
      assert.are.same({}, actual.subgraphs)
      assert.are.same({}, actual.notes)
      assert.are.equal("TD", actual.config.graph_direction)
      assert.is_nil(actual.parsed_direction)
    end
  )

  it(
    "GIVEN unresolved node and note references WHEN normalizing THEN it drops the unresolved data instead of inventing nodes",
    function()
      local actual = normalize.from_parsed({
        direction = nil,
        nodes = {
          A = helpers.given_parsed_node("A", "A", "rectangle"),
        },
        node_order = { "A", "Missing" },
        edges = {
          {
            source = "A",
            target = "Missing",
            label = "ignored",
            style = "solid",
            has_arrow_start = false,
            has_arrow_end = true,
          },
        },
        subgraphs = {},
        notes = {
          { state_id = "Missing", position = "right", text = "ignored note" },
        },
        class_defs = {},
        class_assignments = {},
        node_styles = {},
        link_styles = {},
        warnings = {},
      })

      assert.are.equal(1, #actual.nodes)
      assert.are.equal("A", actual.nodes[1].name)
      assert.are.same({}, actual.edges)
      assert.are.same({}, actual.notes)
    end
  )

  it(
    "GIVEN an empty composite without entry or exit anchors WHEN normalizing THEN external composite edges are skipped",
    function()
      local given_subgraph = helpers.given_parsed_subgraph("Composite", "Composite", "composite", {}, {}, nil)
      local actual = normalize.from_parsed({
        direction = "TD",
        nodes = {
          Outside = helpers.given_parsed_node("Outside", "Outside", "rectangle"),
        },
        node_order = { "Outside" },
        edges = {
          {
            source = "Outside",
            target = "Composite",
            label = "enter",
            style = "solid",
            has_arrow_start = false,
            has_arrow_end = true,
          },
          {
            source = "Composite",
            target = "Outside",
            label = "leave",
            style = "solid",
            has_arrow_start = false,
            has_arrow_end = true,
          },
        },
        subgraphs = { given_subgraph },
        notes = {},
        class_defs = {},
        class_assignments = {},
        node_styles = {},
        link_styles = {},
        warnings = {},
      })

      assert.are.same({}, actual.edges)
      assert.are.equal("Composite", actual.subgraphs[1].id)
      assert.are.same({}, actual.subgraphs[1].nodes)
    end
  )
end)
