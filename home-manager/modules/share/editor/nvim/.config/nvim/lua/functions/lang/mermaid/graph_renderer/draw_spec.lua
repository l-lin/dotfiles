local helpers = require("functions.lang.mermaid.graph_renderer.spec_helper")
local draw = require("functions.lang.mermaid.graph_renderer.draw")
local layout = require("functions.lang.mermaid.graph_renderer.layout")
local normalize = require("functions.lang.mermaid.graph_renderer.normalize")

describe("mermaid.graph_renderer.draw", function()
  it("GIVEN no layout nodes WHEN rendering THEN the draw stage returns an empty output", function()
    local actual = draw.render({
      nodes = {},
      parsed_direction = "TD",
    })
    local expected = {}

    assert.are.same(expected, actual)
  end)

  it("GIVEN a single laid-out node WHEN rendering THEN outer blank margins are trimmed from the final lines", function()
    local given_parsed = helpers.given_empty_parsed_graph("TD")
    given_parsed.nodes.A = helpers.given_parsed_node("A", "A", "rectangle")
    given_parsed.node_order = { "A" }

    local actual = draw.render(layout.prepare_layout(normalize.from_parsed(given_parsed)))
    local expected = {
      "┌───┐",
      "│   │",
      "│ A │",
      "│   │",
      "└───┘",
    }

    assert.are.same(expected, actual)
  end)

  it(
    "GIVEN the same prepared layout in TD and BT WHEN rendering THEN BT swaps the node order while preserving the label text",
    function()
      local given_layout = layout.prepare_layout(normalize.from_parsed(helpers.given_simple_parsed_graph("TD")))

      local actual_td = draw.render(given_layout)
      given_layout.parsed_direction = "BT"
      local actual_bt = draw.render(given_layout)

      local actual_td_a_line
      local actual_td_b_line
      local actual_bt_a_line
      local actual_bt_b_line

      for index, line in ipairs(actual_td) do
        if line:find(" A ", 1, true) then
          actual_td_a_line = index
        end
        if line:find(" B ", 1, true) then
          actual_td_b_line = index
        end
      end

      for index, line in ipairs(actual_bt) do
        if line:find(" A ", 1, true) then
          actual_bt_a_line = index
        end
        if line:find(" B ", 1, true) then
          actual_bt_b_line = index
        end
      end

      assert.is_true(actual_td_a_line < actual_td_b_line)
      assert.is_true(actual_bt_b_line < actual_bt_a_line)
      assert.is_truthy(table.concat(actual_bt, "\n"):find("go", 1, true))
    end
  )
end)
