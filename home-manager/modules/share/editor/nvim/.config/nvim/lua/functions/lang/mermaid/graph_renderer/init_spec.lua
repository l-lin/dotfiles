local helpers = require("functions.lang.mermaid.graph_renderer.spec_helper")
local graph_renderer = require("functions.lang.mermaid.graph_renderer")
local draw = require("functions.lang.mermaid.graph_renderer.draw")
local layout = require("functions.lang.mermaid.graph_renderer.layout")
local normalize = require("functions.lang.mermaid.graph_renderer.normalize")

describe("mermaid.graph_renderer.render_graph", function()
  it(
    "GIVEN parsed graph data WHEN rendering through the public entrypoint THEN it runs the normalize layout and draw pipeline",
    function()
      local given_parsed = helpers.given_simple_parsed_graph("TD")

      local actual = graph_renderer.render_graph(given_parsed)
      local expected = draw.render(layout.prepare_layout(normalize.from_parsed(given_parsed)))

      assert.are.same(expected, actual)
    end
  )

  it(
    "GIVEN an empty parsed graph WHEN rendering through the public entrypoint THEN it returns an empty diagram",
    function()
      local actual = graph_renderer.render_graph(helpers.given_empty_parsed_graph(nil))
      local expected = {}

      assert.are.same(expected, actual)
    end
  )
end)
