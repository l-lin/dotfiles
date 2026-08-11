local helpers = require("functions.lang.mermaid.graph_renderer.spec_helper")
local geometry = require("functions.lang.mermaid.graph_renderer.geometry")

describe("mermaid.graph_renderer.geometry", function()
  it("GIVEN grid and drawing coordinates WHEN using direction helpers THEN they stay internally consistent", function()
    local actual_moved = geometry.move_grid_coord({ x = 2, y = 3 }, geometry.Directions.lower_left)
    local expected_moved = { x = 2, y = 5 }

    assert.are.same(expected_moved, actual_moved)
    assert.is_true(geometry.same_grid_coord({ x = 4, y = 5 }, { x = 4, y = 5 }))
    assert.is_true(geometry.same_drawing_coord({ x = 8, y = 9 }, { x = 8, y = 9 }))
    assert.are.equal("7,11", geometry.grid_key({ x = 7, y = 11 }))
    assert.are.same(geometry.Directions.upper_right, geometry.determine_direction({ x = 1, y = 3 }, { x = 4, y = 0 }))
    assert.are.same(geometry.Directions.lower_left, geometry.opposite_direction(geometry.Directions.upper_right))
  end)

  it(
    "GIVEN equivalent and missing directions WHEN comparing THEN logical direction identity wins over table identity",
    function()
      local actual_same = geometry.same_direction(geometry.Directions.up, { id = "up", x = 99, y = 99 })
      local actual_missing = geometry.same_direction(nil, geometry.Directions.up)
      local actual_both_missing = geometry.same_direction(nil, nil)

      assert.is_true(actual_same)
      assert.is_false(actual_missing)
      assert.is_true(actual_both_missing)
    end
  )

  it(
    "GIVEN Unicode multiline box labels WHEN measuring THEN box sizing keeps UTF-8 width and odd inner height",
    function()
      local actual = geometry.measure_node({ shape = "rectangle", display_label = "宽\nAB", layout_direction = nil }, {
        graph_direction = "TD",
        box_border_padding = 1,
      })
      local expected = {
        width = 6,
        height = 7,
        grid_columns = { 1, 4, 1 },
        grid_rows = { 1, 5, 1 },
      }

      assert.are.same(expected, actual)
    end
  )

  it(
    "GIVEN state bars without explicit layout direction WHEN measuring THEN they inherit the graph direction",
    function()
      local actual = geometry.measure_node({ shape = "state-join", display_label = "", layout_direction = nil }, {
        graph_direction = "LR",
        box_border_padding = 1,
      })
      local expected = {
        width = 3,
        height = 7,
        grid_columns = { 1, 1, 1 },
        grid_rows = { 2, 3, 2 },
      }

      assert.are.same(expected, actual)
    end
  )

  it(
    "GIVEN boxed shapes and unknown corners WHEN attaching and decorating THEN helpers fall back predictably",
    function()
      local actual_center = geometry.box_attachment_point(
        geometry.Directions.middle,
        { width = 7, height = 5 },
        { x = 10, y = 20 }
      )
      local actual_upper_left = geometry.box_attachment_point(
        geometry.Directions.upper_left,
        { width = 7, height = 5 },
        { x = 10, y = 20 }
      )
      local actual_corners = geometry.shape_corners("mystery-shape")

      assert.are.same({ x = 13, y = 22 }, actual_center)
      assert.are.same({ x = 10, y = 20 }, actual_upper_left)
      assert.are.same({ tl = "┌", tr = "┐", bl = "└", br = "┘" }, actual_corners)
    end
  )

  it(
    "GIVEN state pseudostates and bars WHEN measuring and attaching THEN shape-specific geometry is preserved",
    function()
      local actual_circle = geometry.measure_node(
        { shape = "state-start", display_label = "", layout_direction = nil },
        helpers.given_layout_config()
      )
      local expected_circle = {
        width = 3,
        height = 3,
        grid_columns = { 1, 1, 1 },
        grid_rows = { 1, 1, 1 },
      }
      local actual_circle_attachment = geometry.shape_attachment_point(
        { shape = "state-choice", layout_direction = nil },
        geometry.Directions.left,
        expected_circle,
        { x = 10, y = 20 }
      )
      local actual_vertical_bar = geometry.measure_node(
        { shape = "state-fork", display_label = "", layout_direction = "LR" },
        helpers.given_layout_config()
      )
      local actual_vertical_attachment = geometry.shape_attachment_point(
        { shape = "state-fork", layout_direction = "LR" },
        geometry.Directions.down,
        actual_vertical_bar,
        { x = 10, y = 20 }
      )
      local actual_horizontal_bar = geometry.measure_node(
        { shape = "state-join", display_label = "", layout_direction = nil },
        helpers.given_layout_config()
      )
      local actual_horizontal_attachment = geometry.shape_attachment_point(
        { shape = "state-join", layout_direction = "TD" },
        geometry.Directions.left,
        actual_horizontal_bar,
        { x = 10, y = 20 }
      )

      assert.are.same(expected_circle, actual_circle)
      assert.are.same({ x = 11, y = 21 }, actual_circle_attachment)
      assert.are.same(
        { width = 3, height = 7, grid_columns = { 1, 1, 1 }, grid_rows = { 2, 3, 2 } },
        actual_vertical_bar
      )
      assert.are.same({ x = 11, y = 26 }, actual_vertical_attachment)
      assert.are.same(
        { width = 7, height = 3, grid_columns = { 2, 3, 2 }, grid_rows = { 1, 1, 1 } },
        actual_horizontal_bar
      )
      assert.are.same({ x = 10, y = 21 }, actual_horizontal_attachment)
      assert.are.equal("◉", geometry.state_pseudostate_symbol("state-end"))
      assert.are.equal("◇", geometry.state_pseudostate_symbol("state-choice"))
      assert.are.equal("●", geometry.state_pseudostate_symbol("state-start"))
      assert.are.same({ tl = "╟", tr = "╢", bl = "╟", br = "╢" }, geometry.shape_corners("subroutine"))
    end
  )
end)
