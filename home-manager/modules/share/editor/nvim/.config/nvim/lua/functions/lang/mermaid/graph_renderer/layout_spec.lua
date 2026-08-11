local helpers = require("functions.lang.mermaid.graph_renderer.spec_helper")
local geometry = require("functions.lang.mermaid.graph_renderer.geometry")
local layout = require("functions.lang.mermaid.graph_renderer.layout")
local normalize = require("functions.lang.mermaid.graph_renderer.normalize")
local parser = require("functions.lang.mermaid.parser")
local state_parser = require("functions.lang.mermaid.state.parser")

describe("mermaid.graph_renderer.layout", function()
  it(
    "GIVEN a normalized two-node graph WHEN preparing layout THEN nodes receive stable grid and drawing coordinates",
    function()
      local actual = layout.prepare_layout(normalize.from_parsed(helpers.given_simple_parsed_graph("TD")))
      local actual_first_node = actual.nodes[1]
      local actual_size = layout.node_render_size(actual, actual_first_node)
      local actual_attachment = layout.node_attachment_point(actual, actual_first_node, geometry.Directions.down)
      local actual_grid_origin = layout.grid_to_drawing_coord(actual, actual_first_node.grid_coord)

      assert.are.same(actual_grid_origin, actual_first_node.drawing_coord)
      assert.are.same({ width = 6, height = 5 }, actual_size)
      assert.are.same(
        { x = actual_first_node.drawing_coord.x + 3, y = actual_first_node.drawing_coord.y + 4 },
        actual_attachment
      )
      assert.is_true(#actual.edges[1].path >= 2)
      assert.is_true(#actual.edges[1].label_line >= 2)
      assert.is_true(actual.canvas_max_x > 0)
      assert.is_true(actual.canvas_max_y > 0)
    end
  )

  it(
    "GIVEN an empty normalized graph WHEN preparing layout THEN it returns the empty working graph without coordinates",
    function()
      local actual = layout.prepare_layout(normalize.from_parsed(helpers.given_empty_parsed_graph("TD")))

      assert.are.same({}, actual.nodes)
      assert.are.same({}, actual.edges)
      assert.are.same({}, actual.subgraphs)
      assert.are.equal(0, actual.canvas_max_x)
      assert.are.equal(0, actual.canvas_max_y)
    end
  )

  it(
    "GIVEN explicit row column and graph offsets WHEN converting coordinates THEN direction offsets are included in the drawing point",
    function()
      local actual = layout.grid_to_drawing_coord({
        column_width = { [0] = 2, [1] = 4, [2] = 6, [3] = 8 },
        row_height = { [0] = 3, [1] = 5, [2] = 7 },
        offset_x = 10,
        offset_y = 20,
      }, {
        x = 1,
        y = 1,
      }, geometry.Directions.right)
      local expected = { x = 26, y = 31 }

      assert.are.same(expected, actual)
    end
  )

  it(
    "GIVEN a branching edge turn in a top-down graph WHEN locating its branch label THEN the origin sits above the bend instead of under the whole fanout",
    function()
      local actual = layout.get_branch_label_origin({
        column_width = { [0] = 1, [1] = 5 },
        row_height = { [0] = 1, [1] = 5 },
        offset_x = 0,
        offset_y = 0,
        config = { graph_direction = "TD" },
      }, {
        text = "yes",
        path = { { x = 0, y = 0 }, { x = 1, y = 0 }, { x = 1, y = 1 } },
        draw_path = nil,
        start_dir = geometry.Directions.right,
        start_attachment_override = { x = 0, y = 0 },
        from = { drawing_coord = { x = 0, y = 0 }, grid_coord = { x = 0, y = 0 }, shape = "rectangle" },
      })
      local expected = { x = 2, y = 0 }

      assert.are.same(expected, actual)
    end
  )

  it(
    "GIVEN a branch edge whose composite attachment clipped the visible path WHEN locating its label THEN the original turn still decides the origin",
    function()
      local actual = layout.get_branch_label_origin({
        column_width = { [0] = 1, [1] = 1 },
        row_height = { [0] = 1, [1] = 1, [2] = 1 },
        offset_x = 0,
        offset_y = 0,
        config = { graph_direction = "TD" },
      }, {
        text = "go",
        path = { { x = 0, y = 0 }, { x = 0, y = 1 }, { x = 1, y = 1 }, { x = 1, y = 2 } },
        draw_path = { { x = 0, y = 0 }, { x = 0, y = 1 } },
        start_dir = geometry.Directions.down,
        start_attachment_override = { x = 0, y = 0 },
        from = { drawing_coord = { x = 0, y = 0 }, grid_coord = { x = 0, y = 0 }, shape = "rectangle" },
      })

      assert.are.same({ x = 2, y = 0 }, actual)
    end
  )

  it(
    "GIVEN non-turning branch labels WHEN locating their origins THEN each fallback direction offsets from the attachment point",
    function()
      local given_graph = {
        column_width = {},
        row_height = {},
        offset_x = 0,
        offset_y = 0,
      }

      local actual_left = layout.get_branch_label_origin(given_graph, {
        text = "ok",
        path = { { x = 0, y = 0 }, { x = 0, y = 1 } },
        draw_path = nil,
        start_dir = geometry.Directions.left,
        start_attachment_override = { x = 10, y = 4 },
        from = { drawing_coord = { x = 0, y = 0 }, grid_coord = { x = 0, y = 0 }, shape = "rectangle" },
      })
      local actual_up = layout.get_branch_label_origin(given_graph, {
        text = "ok",
        path = { { x = 0, y = 0 }, { x = 0, y = 1 } },
        draw_path = nil,
        start_dir = geometry.Directions.up,
        start_attachment_override = { x = 10, y = 4 },
        from = { drawing_coord = { x = 0, y = 0 }, grid_coord = { x = 0, y = 0 }, shape = "rectangle" },
      })

      assert.are.same({ x = 6, y = 5 }, actual_left)
      assert.are.same({ x = 12, y = 3 }, actual_up)
    end
  )

  it(
    "GIVEN a composite state with an external incoming edge and parallel regions WHEN preparing layout THEN the internal regions stay aligned side by side in source order",
    function()
      local source = table.concat({
        "stateDiagram-v2",
        "  state battery_check <<choice>>",
        "  [*] --> PowerOn",
        "  PowerOn --> battery_check",
        "  battery_check --> LowPowerMode : battery < 20%",
        "  battery_check --> Active : battery >= 20%",
        "",
        "  state Active {",
        "    [*] --> Playing",
        "    Playing --> Paused : pause",
        "    Paused --> Playing : play",
        "    --",
        "    [*] --> ScreenOn",
        "    ScreenOn --> ScreenDimmed : idle 30s",
        "    ScreenDimmed --> ScreenOn : touch",
        "  }",
        "",
        "  LowPowerMode --> [*] : power off",
        "  Active --> [*] : power off",
      }, "\n")

      local parsed = assert(state_parser.parse(parser.preprocess_source(source)))
      local actual = layout.prepare_layout(normalize.from_parsed(parsed))
      local actual_nodes_by_name = {}
      for _, node in ipairs(actual.nodes) do
        actual_nodes_by_name[node.name] = node
      end

      local actual_playing = assert(actual_nodes_by_name.Playing)
      local actual_screen_on = assert(actual_nodes_by_name.ScreenOn)
      local actual_paused = assert(actual_nodes_by_name.Paused)
      local actual_screen_dimmed = assert(actual_nodes_by_name.ScreenDimmed)

      assert.is_true(math.abs(actual_playing.drawing_coord.y - actual_screen_on.drawing_coord.y) <= 2)
      assert.is_true(math.abs(actual_paused.drawing_coord.y - actual_screen_dimmed.drawing_coord.y) <= 2)
      assert.is_true(actual_playing.drawing_coord.x < actual_screen_on.drawing_coord.x)
      assert.is_true(actual_paused.drawing_coord.x < actual_screen_dimmed.drawing_coord.x)
    end
  )
end)
