local text = require("functions.lang.mermaid.text")

---The renderer reserves every logical node in a 3x3 grid neighborhood.
---These direction deltas therefore move between neighboring routing cells, not raw
---character coordinates. Keeping the deltas explicit makes attachment math easier to
---read than the old anonymous `{ x = 1, y = 0 }` tables scattered everywhere.
---@type table<dotfiles.mermaid.graph_renderer.DirectionId, dotfiles.mermaid.graph_renderer.Direction>
local Directions = {
  up = { id = "up", x = 1, y = 0 },
  down = { id = "down", x = 1, y = 2 },
  left = { id = "left", x = 0, y = 1 },
  right = { id = "right", x = 2, y = 1 },
  upper_right = { id = "upper_right", x = 2, y = 0 },
  upper_left = { id = "upper_left", x = 0, y = 0 },
  lower_right = { id = "lower_right", x = 2, y = 2 },
  lower_left = { id = "lower_left", x = 0, y = 2 },
  middle = { id = "middle", x = 1, y = 1 },
}

---@type table<dotfiles.mermaid.graph_renderer.DirectionId, dotfiles.mermaid.graph_renderer.DirectionId>
local OPPOSITE_DIRECTION_ID = {
  up = "down",
  down = "up",
  left = "right",
  right = "left",
  upper_right = "lower_left",
  upper_left = "lower_right",
  lower_right = "upper_left",
  lower_left = "upper_right",
  middle = "middle",
}

---@type table<string, dotfiles.mermaid.graph_renderer.CornerGlyphs>
local SHAPE_CORNERS = {
  rectangle = { tl = "┌", tr = "┐", bl = "└", br = "┘" },
  rounded = { tl = "╭", tr = "╮", bl = "╰", br = "╯" },
  circle = { tl = "◯", tr = "◯", bl = "◯", br = "◯" },
  doublecircle = { tl = "◎", tr = "◎", bl = "◎", br = "◎" },
  diamond = { tl = "◇", tr = "◇", bl = "◇", br = "◇" },
  hexagon = { tl = "⌜", tr = "⌝", bl = "⌞", br = "⌟" },
  stadium = { tl = "(", tr = ")", bl = "(", br = ")" },
  subroutine = { tl = "╟", tr = "╢", bl = "╟", br = "╢" },
  cylinder = { tl = "╭", tr = "╮", bl = "╰", br = "╯" },
  asymmetric = { tl = "▷", tr = "┐", bl = "▷", br = "┘" },
  trapezoid = { tl = "/", tr = "\\", bl = "└", br = "┘" },
  ["trapezoid-alt"] = { tl = "┌", tr = "┐", bl = "\\", br = "/" },
  ["state-start"] = { tl = "●", tr = "●", bl = "●", br = "●" },
  ["state-end"] = { tl = "╔", tr = "╗", bl = "╚", br = "╝" },
}

---Check whether two direction objects represent the same logical direction.
---@param left dotfiles.mermaid.graph_renderer.Direction|nil the first direction to compare, or nil when absent.
---@param right dotfiles.mermaid.graph_renderer.Direction|nil the second direction to compare, or nil when absent.
---@return boolean matches true when both directions are logically the same.
local function same_direction(left, right)
  return left == right or (left and right and left.id == right.id) or false
end

---Check whether two grid coordinates refer to the same grid cell.
---@param left dotfiles.mermaid.graph_renderer.GridCoord the first grid coordinate to compare.
---@param right dotfiles.mermaid.graph_renderer.GridCoord the second grid coordinate to compare.
---@return boolean matches true when both coordinates have the same grid x and y values.
local function same_grid_coord(left, right)
  return left.x == right.x and left.y == right.y
end

---Check whether two drawing coordinates refer to the same canvas position.
---@param left dotfiles.mermaid.graph_renderer.DrawingCoord the first drawing coordinate to compare.
---@param right dotfiles.mermaid.graph_renderer.DrawingCoord the second drawing coordinate to compare.
---@return boolean matches true when both coordinates have the same drawing x and y values.
local function same_drawing_coord(left, right)
  return left.x == right.x and left.y == right.y
end

---Convert a grid coordinate into the stable string key used by occupancy maps.
---@param coord dotfiles.mermaid.graph_renderer.GridCoord the grid coordinate to encode as a string key.
---@return string key the serialized `x,y` key for the coordinate.
local function grid_key(coord)
  return string.format("%d,%d", coord.x, coord.y)
end

---Move a grid coordinate by one logical routing step in the given direction.
---@param coord dotfiles.mermaid.graph_renderer.GridCoord the starting grid coordinate to offset.
---@param direction dotfiles.mermaid.graph_renderer.Direction the logical routing direction to apply.
---@return dotfiles.mermaid.graph_renderer.GridCoord moved_coord the shifted grid coordinate after applying the direction delta.
local function move_grid_coord(coord, direction)
  return {
    x = coord.x + direction.x,
    y = coord.y + direction.y,
  }
end

---Determine the logical direction from one coordinate to another.
---@param from dotfiles.mermaid.graph_renderer.GridCoord|dotfiles.mermaid.graph_renderer.DrawingCoord the starting coordinate.
---@param to dotfiles.mermaid.graph_renderer.GridCoord|dotfiles.mermaid.graph_renderer.DrawingCoord the destination coordinate.
---@return dotfiles.mermaid.graph_renderer.Direction direction the logical direction from the start toward the destination.
local function determine_direction(from, to)
  if from.x == to.x then
    return from.y < to.y and Directions.down or Directions.up
  end
  if from.y == to.y then
    return from.x < to.x and Directions.right or Directions.left
  end
  if from.x < to.x then
    return from.y < to.y and Directions.lower_right or Directions.upper_right
  end
  return from.y < to.y and Directions.lower_left or Directions.upper_left
end

---Look up the logical opposite of a direction.
---@param direction dotfiles.mermaid.graph_renderer.Direction the direction whose opposite should be returned.
---@return dotfiles.mermaid.graph_renderer.Direction opposite the direction facing back toward the source.
local function opposite_direction(direction)
  return Directions[OPPOSITE_DIRECTION_ID[direction.id]]
end

---Check whether a node shape renders as a circular state pseudostate.
---@param shape string the node shape identifier to classify.
---@return boolean is_circle_pseudostate true when the shape is a circular pseudostate.
local function is_state_circle_pseudostate(shape)
  return shape == "state-start" or shape == "state-end" or shape == "state-choice"
end

---Check whether a node shape renders as a state fork or join bar.
---@param shape string the node shape identifier to classify.
---@return boolean is_bar true when the shape is a bar-style pseudostate.
local function is_state_bar(shape)
  return shape == "state-fork" or shape == "state-join"
end

---Check whether a node shape is any supported state pseudostate.
---@param shape string the node shape identifier to classify.
---@return boolean is_pseudostate true when the shape is a circular or bar pseudostate.
local function is_state_pseudostate(shape)
  return is_state_circle_pseudostate(shape) or is_state_bar(shape)
end

---Check whether a pseudostate shape branches outgoing control flow.
---@param shape string the node shape identifier to classify.
---@return boolean is_branching true when the shape uses branching-specific routing rules.
local function is_branching_pseudostate(shape)
  return shape == "state-choice" or shape == "state-fork"
end

---Pick the single-character symbol used to draw a state pseudostate.
---@param shape string the pseudostate shape identifier to render.
---@return string symbol the glyph used for that pseudostate shape.
local function state_pseudostate_symbol(shape)
  if shape == "state-end" then
    return "◉"
  end
  if shape == "state-choice" then
    return "◇"
  end
  return "●"
end

---Pick the corner glyph set used to draw a boxed node shape.
---@param shape string the node shape identifier whose border corners should be looked up.
---@return dotfiles.mermaid.graph_renderer.CornerGlyphs corners the corner glyph set for the shape, or rectangle corners as a fallback.
local function shape_corners(shape)
  return SHAPE_CORNERS[shape] or SHAPE_CORNERS.rectangle
end

---Measure a standard boxed label and convert it into renderer node dimensions.
---@param label string the node label text whose width and height should be measured.
---@param padding integer the number of inner padding cells to preserve around the label text.
---@return dotfiles.mermaid.graph_renderer.NodeDimensions dimensions the measured node dimensions and 3x3 grid budgets for a standard box.
local function measure_box(label, padding)
  local max_line_width = text.max_line_width(label)
  local line_count = text.line_count(label)
  local inner_width = 2 * padding + max_line_width
  local width = inner_width + 2
  local raw_inner_height = line_count + 2 * padding
  local inner_height = raw_inner_height % 2 == 0 and (raw_inner_height + 1) or raw_inner_height
  local height = inner_height + 2

  return {
    width = width,
    height = height,
    grid_columns = { 1, inner_width, 1 },
    grid_rows = { 1, inner_height, 1 },
  }
end

---Measure a non-pseudostate node shape and convert it into renderer node dimensions.
---@param shape string the node shape identifier whose footprint should be measured.
---@param label string the node label text whose width and height should influence the footprint.
---@param padding integer the number of inner padding cells to preserve around the label text.
---@return dotfiles.mermaid.graph_renderer.NodeDimensions dimensions the measured node dimensions and 3x3 grid budgets for the shape.
local function measure_shape(shape, label, padding)
  if shape == "stadium" then
    local max_line_width = text.max_line_width(label)
    local line_count = text.line_count(label)
    local inner_width = 2 * padding + max_line_width
    local width = inner_width + 4
    local inner_height = line_count + 2 * padding
    local height = math.max(inner_height + 2, 3)
    return {
      width = width,
      height = height,
      grid_columns = { 2, inner_width, 2 },
      grid_rows = { 1, inner_height, 1 },
    }
  end

  if shape == "subroutine" then
    local max_line_width = text.max_line_width(label)
    local line_count = text.line_count(label)
    local inner_width = 2 * padding + max_line_width
    local inner_height = line_count + 2 * padding
    return {
      width = inner_width + 4,
      height = inner_height + 2,
      grid_columns = { 2, inner_width, 2 },
      grid_rows = { 1, inner_height, 1 },
    }
  end

  if shape == "cylinder" then
    local max_line_width = text.max_line_width(label)
    local line_count = text.line_count(label)
    local inner_width = 2 * padding + max_line_width
    local inner_height = line_count + 2 * padding + 2
    return {
      width = inner_width + 2,
      height = inner_height + 2,
      grid_columns = { 1, inner_width, 1 },
      grid_rows = { 2, inner_height - 2, 2 },
    }
  end

  return measure_box(label, padding)
end

---Measure a state fork or join bar for the current layout direction.
---@param layout_direction dotfiles.mermaid.graph_renderer.GraphDirection the graph direction that decides whether the bar is vertical or horizontal.
---@return dotfiles.mermaid.graph_renderer.NodeDimensions dimensions the fixed dimensions and grid budgets for the state bar.
local function measure_state_bar(layout_direction)
  if layout_direction == "LR" then
    return {
      width = 3,
      height = 7,
      grid_columns = { 1, 1, 1 },
      grid_rows = { 2, 3, 2 },
    }
  end

  return {
    width = 7,
    height = 3,
    grid_columns = { 2, 3, 2 },
    grid_rows = { 1, 1, 1 },
  }
end

---Measure any supported node into renderer dimensions.
---@param node dotfiles.mermaid.graph_renderer.NormalizedNode|dotfiles.mermaid.graph_renderer.LayoutNode the node whose rendered footprint should be computed.
---@param config dotfiles.mermaid.graph_renderer.RendererConfig the renderer configuration that provides padding and default direction rules.
---@return dotfiles.mermaid.graph_renderer.NodeDimensions dimensions the measured width, height, and grid budgets for the node.
local function measure_node(node, config)
  if is_state_circle_pseudostate(node.shape) then
    return {
      width = 3,
      height = 3,
      grid_columns = { 1, 1, 1 },
      grid_rows = { 1, 1, 1 },
    }
  end

  if is_state_bar(node.shape) then
    local layout_direction = node.layout_direction or config.graph_direction
    return measure_state_bar(layout_direction)
  end

  return measure_shape(node.shape, node.display_label, config.box_border_padding)
end

---Choose the drawing coordinate where an edge should attach to a rectangular box footprint.
---@param direction dotfiles.mermaid.graph_renderer.Direction the approach or departure direction of the edge.
---@param dimensions { width: integer, height: integer } the rendered width and height of the boxed shape.
---@param base_coord dotfiles.mermaid.graph_renderer.DrawingCoord the top-left drawing coordinate of the shape.
---@return dotfiles.mermaid.graph_renderer.DrawingCoord attachment_point the drawing coordinate where the edge should meet the box.
local function box_attachment_point(direction, dimensions, base_coord)
  local width = dimensions.width
  local height = dimensions.height
  local center_x = base_coord.x + math.floor(width / 2)
  local center_y = base_coord.y + math.floor(height / 2)

  if same_direction(direction, Directions.up) then
    return { x = center_x, y = base_coord.y }
  end
  if same_direction(direction, Directions.down) then
    return { x = center_x, y = base_coord.y + height - 1 }
  end
  if same_direction(direction, Directions.left) then
    return { x = base_coord.x, y = center_y }
  end
  if same_direction(direction, Directions.right) then
    return { x = base_coord.x + width - 1, y = center_y }
  end
  if same_direction(direction, Directions.upper_left) then
    return { x = base_coord.x, y = base_coord.y }
  end
  if same_direction(direction, Directions.upper_right) then
    return { x = base_coord.x + width - 1, y = base_coord.y }
  end
  if same_direction(direction, Directions.lower_left) then
    return { x = base_coord.x, y = base_coord.y + height - 1 }
  end
  if same_direction(direction, Directions.lower_right) then
    return { x = base_coord.x + width - 1, y = base_coord.y + height - 1 }
  end
  return { x = center_x, y = center_y }
end

---Choose the drawing coordinate where an edge should attach to a rendered node shape.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the laid out node whose rendered shape determines the attachment behavior.
---@param direction dotfiles.mermaid.graph_renderer.Direction the approach or departure direction of the edge.
---@param dimensions { width: integer, height: integer } the rendered width and height of the node shape.
---@param base_coord dotfiles.mermaid.graph_renderer.DrawingCoord the top-left drawing coordinate of the shape.
---@return dotfiles.mermaid.graph_renderer.DrawingCoord attachment_point the drawing coordinate where the edge should meet the rendered shape.
local function shape_attachment_point(node, direction, dimensions, base_coord)
  if is_state_circle_pseudostate(node.shape) then
    local center_x = base_coord.x + math.floor(dimensions.width / 2)
    local center_y = base_coord.y + math.floor(dimensions.height / 2)
    return { x = center_x, y = center_y }
  end

  if is_state_bar(node.shape) then
    local center_x = base_coord.x + math.floor(dimensions.width / 2)
    local center_y = base_coord.y + math.floor(dimensions.height / 2)

    if node.layout_direction == "LR" then
      if
        same_direction(direction, Directions.up)
        or same_direction(direction, Directions.upper_left)
        or same_direction(direction, Directions.upper_right)
      then
        return { x = center_x, y = base_coord.y }
      end
      if
        same_direction(direction, Directions.down)
        or same_direction(direction, Directions.lower_left)
        or same_direction(direction, Directions.lower_right)
      then
        return { x = center_x, y = base_coord.y + dimensions.height - 1 }
      end
      return { x = center_x, y = center_y }
    end

    if
      same_direction(direction, Directions.left)
      or same_direction(direction, Directions.upper_left)
      or same_direction(direction, Directions.lower_left)
    then
      return { x = base_coord.x, y = center_y }
    end
    if
      same_direction(direction, Directions.right)
      or same_direction(direction, Directions.upper_right)
      or same_direction(direction, Directions.lower_right)
    then
      return { x = base_coord.x + dimensions.width - 1, y = center_y }
    end
    return { x = center_x, y = center_y }
  end

  return box_attachment_point(direction, dimensions, base_coord)
end

local M = {}
M.Directions = Directions
M.same_direction = same_direction
M.same_grid_coord = same_grid_coord
M.same_drawing_coord = same_drawing_coord
M.grid_key = grid_key
M.move_grid_coord = move_grid_coord
M.determine_direction = determine_direction
M.opposite_direction = opposite_direction
M.is_state_circle_pseudostate = is_state_circle_pseudostate
M.is_state_bar = is_state_bar
M.is_state_pseudostate = is_state_pseudostate
M.is_branching_pseudostate = is_branching_pseudostate
M.state_pseudostate_symbol = state_pseudostate_symbol
M.shape_corners = shape_corners
M.measure_node = measure_node
M.box_attachment_point = box_attachment_point
M.shape_attachment_point = shape_attachment_point
return M
