local flowchart_renderer = require("functions.lang.mermaid.flowchart.renderer")
local testdata = require("functions.lang.mermaid.testdata")

local function then_rendered_output_matches_fixture(fixture_name)
  local fixture = testdata.load_golden(fixture_name)

  local actual_lines = assert(flowchart_renderer.render(fixture.mermaid))
  local actual = table.concat(actual_lines, "\n")

  local expected = fixture.expected
  assert.are.equal(testdata.normalize_whitespace(expected), testdata.normalize_whitespace(actual))
end

describe("mermaid.flowchart.render", function()
  local upstream_fixtures = {
    "flowchart_ampersand_lhs_and_rhs",
    "flowchart_back_reference_from_child",
    "flowchart_backlink_from_top",
    "flowchart_duplicate_labels",
    "flowchart_graph_bt_direction",
    "flowchart_multiline_edge",
    "flowchart_multiline_node",
    "flowchart_nested_subgraphs_with_labels",
    "flowchart_preserve_order_of_definition",
    "flowchart_self_reference_with_edge",
    "flowchart_self_reference",
    "flowchart_single_node",
    "flowchart_subgraph_complex_nested",
    "flowchart_subgraph_direction_override",
    "flowchart_subgraph_nested",
    "flowchart_subgraphs_cycle_across_groups",
    "flowchart_subgraphs_decision_back_edge",
    "flowchart_subgraphs_development_ci_cd_tb",
    "flowchart_subgraphs_development_ci_cd",
    "flowchart_three_nodes",
    "flowchart_two_nodes_linked",
  }

  for _, fixture_name in ipairs(upstream_fixtures) do
    it(string.format("GIVEN upstream fixture `%s` WHEN rendering THEN output matches the Unicode snapshot", fixture_name), function()
      then_rendered_output_matches_fixture(fixture_name)
    end)
  end

  it("GIVEN a cross-subgraph decision loop fixture WHEN rendering THEN it keeps subgraph titles and branch labels", function()
    local fixture = testdata.load_golden("flowchart_subgraphs_development_ci_cd")

    local actual_lines = assert(flowchart_renderer.render(fixture.mermaid))
    local actual = table.concat(actual_lines, "\n")

    assert.is_truthy(actual:find("Development", 1, true))
    assert.is_truthy(actual:find("Continuous Integration", 1, true))
    assert.is_truthy(actual:find("Deployment", 1, true))
    assert.is_truthy(actual:find("Yes", 1, true))
    assert.is_truthy(actual:find("No", 1, true))
  end)

  it("GIVEN unsupported flowchart syntax WHEN rendering THEN it keeps the partial diagram and appends one raw unsupported line per miss", function()
    local source = table.concat({
      "flowchart TD",
      "  A --> B",
      "  click A callback",
      "  B --> C",
    }, "\n")

    local actual = assert(flowchart_renderer.render(source))
    local expected = {
      "┌───┐",
      "│   │",
      "│ A │",
      "│   │",
      "└─┬─┘",
      "  │",
      "  │",
      "  │",
      "  │",
      "  ▼",
      "┌───┐",
      "│   │",
      "│ B │",
      "│   │",
      "└─┬─┘",
      "  │",
      "  │",
      "  │",
      "  │",
      "  ▼",
      "┌───┐",
      "│   │",
      "│ C │",
      "│   │",
      "└───┘",
      "",
      "[unsupported: click A callback]",
    }

    assert.are.equal(testdata.normalize_whitespace(table.concat(expected, "\n")), testdata.normalize_whitespace(table.concat(actual, "\n")))
  end)
end)
