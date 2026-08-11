local canvas = require("functions.lang.mermaid.canvas")
local text = require("functions.lang.mermaid.text")
local geometry = require("functions.lang.mermaid.graph_renderer.geometry")
local layout = require("functions.lang.mermaid.graph_renderer.layout")

local Directions = geometry.Directions

---Stage 3: turn a fully prepared layout graph into canvas overlays.
---
---This file deliberately avoids making layout decisions. If a helper here seems to need
---to "figure out" where something should go, that is a sign the responsibility belongs
---back in `layout.lua` or `route.lua`.

---@type table<dotfiles.mermaid.graph_renderer.LineStyle, dotfiles.mermaid.graph_renderer.LineGlyphs>
local LINE_GLYPHS = {
  solid = { h = "─", v = "│" },
  dotted = { h = "┄", v = "┆" },
  thick = { h = "━", v = "┃" },
}

---Draw the label text centered within a box of the given width and height.
---@param width integer the width of the target box in characters.
---@param height integer the height of the target box in characters.
---@param label string the label text to draw, which may contain newlines for multi-line labels.
---@return dotfiles.mermaid.Canvas canvas a canvas containing the centered label text.
local function draw_centered_lines(width, height, label)
  local box = canvas.mk_canvas(math.max(width - 1, 0), math.max(height - 1, 0))
  local lines = text.split_lines(label)
  local center_y = math.floor((height - 1) / 2)
  local start_y = center_y - math.floor((#lines - 1) / 2)

  for line_index, line in ipairs(lines) do
    local line_width = text.char_len(line)
    local text_x = math.floor((width - 1) / 2) - math.ceil(line_width / 2) + 1
    canvas.draw_text(box, { x = text_x, y = start_y + line_index - 1 }, line, true)
  end

  return box
end

---Draw a node into its own local canvas, including pseudostates, bars, and boxed labels.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph
---@param node dotfiles.mermaid.graph_renderer.LayoutNode
---@param rendered_size { width: integer, height: integer }
---@return dotfiles.mermaid.graph_renderer.DrawingCoord
local function pseudostate_symbol_center(graph, node, rendered_size)
  local center = geometry.shape_attachment_point(node, Directions.middle, rendered_size, { x = 0, y = 0 })
  if rendered_size.width % 2 ~= 0 then
    return center
  end

  if node.shape == "state-end" and graph.innermost_subgraph_by_node[node] == nil then
    center.x = math.max(0, center.x - 1)
    return center
  end

  if node.shape == "state-start" then
    local node_subgraph = graph.innermost_subgraph_by_node[node]
    if node_subgraph and node_subgraph.kind == "region" and rendered_size.height > 3 then
      center.x = math.max(0, center.x - 1)
      return center
    end

    for _, edge in ipairs(graph.edges) do
      if edge.from == node and edge.target_composite_id then
        if
          geometry.same_direction(edge.start_dir, Directions.down)
          or geometry.same_direction(edge.start_dir, Directions.up)
        then
          center.x = math.max(0, center.x - 1)
          return center
        end
      end
    end
  end

  return center
end

---@return dotfiles.mermaid.Canvas canvas a canvas containing only this node's rendered glyphs.
local function draw_node_canvas(graph, node)
  local rendered_size = layout.node_render_size(graph, node)
  local width = rendered_size.width
  local height = rendered_size.height
  local box = canvas.mk_canvas(math.max(width - 1, 0), math.max(height - 1, 0))
  local max_x = width - 1
  local max_y = height - 1
  local center = pseudostate_symbol_center(graph, node, rendered_size)

  if geometry.is_state_circle_pseudostate(node.shape) then
    box[center.x][center.y] = geometry.state_pseudostate_symbol(node.shape)
    return box
  end

  if geometry.is_state_bar(node.shape) then
    if node.layout_direction == "LR" then
      for y = 0, max_y do
        box[center.x][y] = "┃"
      end
    else
      for x = 0, max_x do
        box[x][center.y] = "━"
      end
    end
    return box
  end

  local corners = geometry.shape_corners(node.shape)
  local h_char = node.shape == "state-end" and "═" or "─"
  local v_char = node.shape == "state-end" and "║" or "│"

  for x = 1, max_x - 1 do
    box[x][0] = h_char
    box[x][max_y] = h_char
  end
  for y = 1, max_y - 1 do
    box[0][y] = v_char
    box[max_x][y] = v_char
  end

  box[0][0] = corners.tl
  box[max_x][0] = corners.tr
  box[0][max_y] = corners.bl
  box[max_x][max_y] = corners.br

  local label_canvas = draw_centered_lines(width, height, node.display_label)
  return canvas.merge_canvases(box, { x = 0, y = 0 }, { label_canvas })
end

---Convert a grid-aligned path into drawing coordinates that match the rendered canvas.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that defines the grid-to-canvas mapping.
---@param line dotfiles.mermaid.graph_renderer.GridPath the grid path to convert into drawing coordinates.
---@return dotfiles.mermaid.graph_renderer.DrawingPath drawing_line the converted path in drawing-space coordinates.
local function line_to_drawing(graph, line)
  local drawing_line = {}
  for _, coord in ipairs(line) do
    drawing_line[#drawing_line + 1] = layout.grid_to_drawing_coord(graph, coord)
  end
  return drawing_line
end

---Draw a straight or elbow segment on the target canvas and record the written coordinates.
---@param target_canvas dotfiles.mermaid.Canvas the canvas to mutate with the line glyphs.
---@param from dotfiles.mermaid.graph_renderer.DrawingCoord the starting drawing coordinate for the segment.
---@param to dotfiles.mermaid.graph_renderer.DrawingCoord the ending drawing coordinate for the segment.
---@param offset_from integer the number of cells to skip from the starting coordinate before drawing.
---@param offset_to integer the signed adjustment to apply at the ending coordinate when stopping the draw.
---@param style dotfiles.mermaid.graph_renderer.LineStyle the visual line style to use for the segment glyphs.
---@return dotfiles.mermaid.graph_renderer.DrawingLine drawn the ordered drawing coordinates written to the canvas.
local function draw_line(target_canvas, from, to, offset_from, offset_to, style)
  local direction = geometry.determine_direction(from, to)
  local chars = LINE_GLYPHS[style]
  local drawn = {}

  local function add(x, y, char)
    drawn[#drawn + 1] = { x = x, y = y }
    target_canvas[x][y] = char
  end

  if geometry.same_direction(direction, Directions.up) then
    for y = from.y - offset_from, to.y - offset_to, -1 do
      add(from.x, y, chars.v)
    end
  elseif geometry.same_direction(direction, Directions.down) then
    for y = from.y + offset_from, to.y + offset_to do
      add(from.x, y, chars.v)
    end
  elseif geometry.same_direction(direction, Directions.left) then
    for x = from.x - offset_from, to.x - offset_to, -1 do
      add(x, from.y, chars.h)
    end
  elseif geometry.same_direction(direction, Directions.right) then
    for x = from.x + offset_from, to.x + offset_to do
      add(x, from.y, chars.h)
    end
  elseif geometry.same_direction(direction, Directions.upper_left) then
    for x = from.x - offset_from, to.x, -1 do
      add(x, from.y, chars.h)
    end
    for y = from.y - 1, to.y - offset_to, -1 do
      add(to.x, y, chars.v)
    end
  elseif geometry.same_direction(direction, Directions.upper_right) then
    for x = from.x + offset_from, to.x do
      add(x, from.y, chars.h)
    end
    for y = from.y - 1, to.y - offset_to, -1 do
      add(to.x, y, chars.v)
    end
  elseif geometry.same_direction(direction, Directions.lower_left) then
    for x = from.x - offset_from, to.x, -1 do
      add(x, from.y, chars.h)
    end
    for y = from.y + 1, to.y + offset_to do
      add(to.x, y, chars.v)
    end
  elseif geometry.same_direction(direction, Directions.lower_right) then
    local dx = to.x - from.x
    if dx <= 1 then
      for y = from.y + offset_from, to.y + offset_to do
        add(from.x, y, chars.v)
      end
    else
      for x = from.x + offset_from, to.x do
        add(x, from.y, chars.h)
      end
      for y = from.y + 1, to.y + offset_to do
        add(to.x, y, chars.v)
      end
    end
  end

  return drawn
end

---Pick the box-drawing glyph for the turn between two consecutive segment directions.
---@param previous_direction dotfiles.mermaid.graph_renderer.Direction the direction of travel entering the corner.
---@param next_direction dotfiles.mermaid.graph_renderer.Direction the direction of travel leaving the corner.
---@return string glyph the box-drawing character that best represents the turn.
local function corner_glyph(previous_direction, next_direction)
  if
    (
      geometry.same_direction(previous_direction, Directions.right)
      and geometry.same_direction(next_direction, Directions.down)
    )
    or (
      geometry.same_direction(previous_direction, Directions.up)
      and geometry.same_direction(next_direction, Directions.left)
    )
  then
    return "┐"
  end
  if
    (
      geometry.same_direction(previous_direction, Directions.right)
      and geometry.same_direction(next_direction, Directions.up)
    )
    or (
      geometry.same_direction(previous_direction, Directions.down)
      and geometry.same_direction(next_direction, Directions.left)
    )
  then
    return "┘"
  end
  if
    (
      geometry.same_direction(previous_direction, Directions.left)
      and geometry.same_direction(next_direction, Directions.down)
    )
    or (
      geometry.same_direction(previous_direction, Directions.up)
      and geometry.same_direction(next_direction, Directions.right)
    )
  then
    return "┌"
  end
  if
    (
      geometry.same_direction(previous_direction, Directions.left)
      and geometry.same_direction(next_direction, Directions.up)
    )
    or (
      geometry.same_direction(previous_direction, Directions.down)
      and geometry.same_direction(next_direction, Directions.right)
    )
  then
    return "└"
  end
  return "+"
end

---Overlay corner glyphs for each interior bend in a routed grid path.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph used to convert grid coordinates to drawing coordinates.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy before adding corner glyphs.
---@param grid_path dotfiles.mermaid.graph_renderer.GridPath the routed grid path whose bends should receive corner glyphs.
---@return dotfiles.mermaid.Canvas canvas a copy of the base canvas with corner glyphs applied.
local function draw_corners(graph, base_canvas, grid_path)
  local result = canvas.copy_canvas(base_canvas)

  for index = 2, #grid_path - 1 do
    local coord = grid_path[index]
    local drawing_coord = layout.grid_to_drawing_coord(graph, coord)
    local previous_direction = geometry.determine_direction(grid_path[index - 1], coord)
    local next_direction = geometry.determine_direction(coord, grid_path[index + 1])
    result[drawing_coord.x][drawing_coord.y] = corner_glyph(previous_direction, next_direction)
  end

  return result
end

---Compute centered drawing positions for each line of an edge label.
---@param drawing_line dotfiles.mermaid.graph_renderer.DrawingPath the drawing-space segment that will host the label.
---@param label string the full label text, which may contain multiple lines.
---@param is_upward_edge boolean|nil whether the edge travels upward, used to bias vertical label placement, or nil when not applicable.
---@return dotfiles.mermaid.graph_renderer.LabelPoint[] points the positioned label fragments to draw on the canvas.
local function label_points(drawing_line, label, is_upward_edge)
  local points = {}
  if #drawing_line < 2 then
    return points
  end

  local min_x = math.min(drawing_line[1].x, drawing_line[2].x)
  local max_x = math.max(drawing_line[1].x, drawing_line[2].x)
  local min_y = math.min(drawing_line[1].y, drawing_line[2].y)
  local max_y = math.max(drawing_line[1].y, drawing_line[2].y)
  local middle_x = min_x + math.floor((max_x - min_x) / 2)
  local middle_y = min_y + math.floor((max_y - min_y) / 2)

  if is_upward_edge ~= nil and min_x == max_x then
    local offset = math.max(1, math.floor((max_y - min_y) / 4))
    middle_y = is_upward_edge and (middle_y + offset) or (middle_y - offset)
  end

  local label_lines = text.split_lines(label)
  local start_y = middle_y - math.floor((#label_lines - 1) / 2)
  for index, line in ipairs(label_lines) do
    local start_x = middle_x - math.floor(text.char_len(line) / 2)
    points[#points + 1] = { x = start_x, y = start_y + index - 1, text = line }
  end

  return points
end

---Draw the text overlay for an edge, including branch labels and multi-line centered labels.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge
---@return dotfiles.mermaid.graph_renderer.DrawingCoord|nil
local function external_left_entry_label_origin(graph, edge)
  local target_subgraph = graph.innermost_subgraph_by_node[edge.to]
  if not target_subgraph or target_subgraph.kind == "region" then
    return nil
  end

  local source_subgraph = graph.innermost_subgraph_by_node[edge.from]
  if source_subgraph == target_subgraph or not geometry.same_direction(edge.end_dir, Directions.left) then
    return nil
  end

  local extra_left_shift = 1
  if geometry.same_direction(edge.start_dir, Directions.right) and #target_subgraph.nodes == 1 then
    extra_left_shift = 2
  end

  return {
    x = math.max(0, target_subgraph.min_x - text.char_len(edge.text) - extra_left_shift),
    y = layout.node_attachment_point(graph, edge.to, edge.end_dir).y,
  }
end

---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides label placement coordinates.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge whose label text should be rendered.
---@return dotfiles.mermaid.Canvas label_canvas a canvas containing only the edge label overlay.
local function draw_arrow_label(graph, edge)
  local label_canvas = canvas.mk_canvas(graph.canvas_max_x, graph.canvas_max_y)
  if edge.text == "" then
    return label_canvas
  end

  if edge.has_branch_label then
    local label_origin = layout.get_branch_label_origin(graph, edge)
    canvas.draw_text(label_canvas, label_origin, edge.text, true)
    return label_canvas
  end

  if edge.source_composite_id and edge.start_attachment_override then
    if geometry.same_direction(edge.start_dir, Directions.right) then
      canvas.draw_text(label_canvas, {
        x = edge.start_attachment_override.x + 3,
        y = edge.start_attachment_override.y,
      }, edge.text, true)
      return label_canvas
    end
    if geometry.same_direction(edge.start_dir, Directions.left) then
      canvas.draw_text(label_canvas, {
        x = math.max(0, edge.start_attachment_override.x - text.char_len(edge.text) - 2),
        y = edge.start_attachment_override.y,
      }, edge.text, true)
      return label_canvas
    end
  end

  local target_label_origin = external_left_entry_label_origin(graph, edge)
  if target_label_origin then
    canvas.draw_text(label_canvas, target_label_origin, edge.text, true)
    return label_canvas
  end

  if #edge.label_line == 0 then
    return label_canvas
  end

  local drawing_line = line_to_drawing(graph, edge.label_line)
  local is_upward_edge = nil
  if #edge.path >= 2 then
    local start_y = edge.path[1].y
    local end_y = edge.path[#edge.path].y
    if end_y < start_y then
      is_upward_edge = true
    elseif end_y > start_y then
      is_upward_edge = false
    end
  end

  for _, point in ipairs(label_points(drawing_line, edge.text, is_upward_edge)) do
    canvas.draw_text(label_canvas, point, point.text, true)
  end
  return label_canvas
end

---Check whether another edge already arrives at the source node on the same side this edge wants to leave.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph whose edges should be scanned.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge whose source side should be checked for competing arrivals.
---@return boolean has_matching_arrival true when another edge targets the same node from the same border side.
local function has_incoming_edge_on_start_side(graph, edge)
  for _, other_edge in ipairs(graph.edges) do
    if
      other_edge ~= edge
      and other_edge.to == edge.from
      and geometry.same_direction(other_edge.end_dir, edge.start_dir)
    then
      return true
    end
  end

  return false
end

---Draw the junction glyph where an edge exits a boxed source node.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides the source node's forward layout direction.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy before adding the source junction glyph.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge whose source border may need a junction glyph.
---@param path dotfiles.mermaid.graph_renderer.GridPath the routed edge path in grid coordinates.
---@param first_line dotfiles.mermaid.graph_renderer.DrawingLine the first rendered segment of the edge path.
---@return dotfiles.mermaid.Canvas canvas a copy of the base canvas with the source box junction glyph applied.
local function draw_box_start(graph, base_canvas, edge, path, first_line)
  local result = canvas.copy_canvas(base_canvas)
  if geometry.is_state_pseudostate(edge.from.shape) or #path < 2 then
    return result
  end

  for _, other_edge in ipairs(graph.edges) do
    if other_edge ~= edge and other_edge.from == edge.to and other_edge.to == edge.from and #path > 2 then
      return result
    end
  end

  if edge.from.shape == "rectangle" and has_incoming_edge_on_start_side(graph, edge) then
    return result
  end

  local from = first_line[1]
  local direction = geometry.determine_direction(path[1], path[2])
  if geometry.same_direction(direction, Directions.up) then
    result[from.x][from.y + 1] = "┴"
  elseif geometry.same_direction(direction, Directions.down) then
    result[from.x][from.y - 1] = "┬"
  elseif geometry.same_direction(direction, Directions.left) then
    result[from.x + 1][from.y] = "┤"
  elseif geometry.same_direction(direction, Directions.right) then
    result[from.x - 1][from.y] = "├"
  end
  return result
end

---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph
---@param base_canvas dotfiles.mermaid.Canvas
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge
---@return dotfiles.mermaid.Canvas
local function draw_box_end(graph, base_canvas, edge)
  local result = canvas.copy_canvas(base_canvas)
  if geometry.is_state_pseudostate(edge.to.shape) then
    return result
  end

  local target = edge.end_attachment_override or layout.node_attachment_point(graph, edge.to, edge.end_dir)
  if geometry.same_direction(edge.end_dir, Directions.up) then
    result[target.x][target.y] = "┴"
  elseif geometry.same_direction(edge.end_dir, Directions.down) then
    result[target.x][target.y] = "┬"
  elseif geometry.same_direction(edge.end_dir, Directions.left) then
    result[target.x][target.y] = "┤"
  elseif geometry.same_direction(edge.end_dir, Directions.right) then
    result[target.x][target.y] = "├"
  end

  return result
end

---Pick the closest arrowhead glyph for a segment direction.
---@param direction dotfiles.mermaid.graph_renderer.Direction the direction the arrowhead should face.
---@return string glyph the arrowhead character that best matches the direction.
local function arrowhead_glyph(direction)
  if geometry.same_direction(direction, Directions.up) then
    return "▲"
  end
  if geometry.same_direction(direction, Directions.down) then
    return "▼"
  end
  if geometry.same_direction(direction, Directions.left) then
    return ""
  end
  if geometry.same_direction(direction, Directions.right) then
    return ""
  end
  if geometry.same_direction(direction, Directions.upper_right) then
    return "◥"
  end
  if geometry.same_direction(direction, Directions.upper_left) then
    return "◤"
  end
  if geometry.same_direction(direction, Directions.lower_right) then
    return "◢"
  end
  if geometry.same_direction(direction, Directions.lower_left) then
    return "◣"
  end
  return "●"
end

---Draw an arrowhead at the end of a rendered segment, falling back when direction is ambiguous.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy before placing the arrowhead glyph.
---@param last_line dotfiles.mermaid.graph_renderer.DrawingLine the final rendered segment whose endpoint receives the arrowhead.
---@param fallback_direction dotfiles.mermaid.graph_renderer.Direction the direction to use when the rendered segment does not imply one clearly.
---@return dotfiles.mermaid.Canvas arrow_canvas a copy of the base canvas with the arrowhead applied.
local function draw_arrow_head(base_canvas, last_line, fallback_direction)
  local arrow_canvas = canvas.copy_canvas(base_canvas)
  if #last_line == 0 then
    return arrow_canvas
  end

  local from = last_line[1]
  local last_position = last_line[#last_line]
  local direction = geometry.determine_direction(from, last_position)
  if #last_line == 1 or geometry.same_direction(direction, Directions.middle) then
    direction = fallback_direction
  end

  arrow_canvas[last_position.x][last_position.y] = arrowhead_glyph(direction)
  return arrow_canvas
end

---Draw every segment in an edge path and collect metadata needed for later overlays.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides attachment and grid-to-drawing coordinates.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy before drawing the edge path.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge whose routed path should be rendered.
---@return dotfiles.mermaid.Canvas path_canvas a canvas containing the rendered edge path segments.
---@return dotfiles.mermaid.graph_renderer.DrawingLine[] lines_drawn the per-segment drawing coordinates produced while rendering the path.
---@return dotfiles.mermaid.graph_renderer.Direction[] directions the grid directions associated with each rendered segment.
local function draw_path(graph, base_canvas, edge)
  local path = edge.draw_path or edge.path
  local target_canvas = canvas.copy_canvas(base_canvas)
  local previous_coord = path[1]
  local lines_drawn = {}
  local directions = {}

  for index = 2, #path do
    local next_coord = path[index]
    local previous_drawing = index == 2
        and (edge.start_attachment_override or layout.node_attachment_point(graph, edge.from, edge.start_dir))
      or layout.grid_to_drawing_coord(graph, previous_coord)
    local next_drawing = index == #path
        and (edge.end_attachment_override or layout.node_attachment_point(graph, edge.to, edge.end_dir))
      or layout.grid_to_drawing_coord(graph, next_coord)

    if not geometry.same_drawing_coord(previous_drawing, next_drawing) then
      local direction = geometry.determine_direction(previous_coord, next_coord)
      local segment = draw_line(target_canvas, previous_drawing, next_drawing, 1, -1, edge.style)
      if #segment == 0 then
        segment[1] = previous_drawing
      end
      lines_drawn[#lines_drawn + 1] = segment
      directions[#directions + 1] = direction
    end
    previous_coord = next_coord
  end

  return target_canvas, lines_drawn, directions
end

---Build the overlay canvases needed to render a standard, non-bundled edge.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides routing and attachment information.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy for each edge overlay.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the non-bundled edge to render.
---@return dotfiles.mermaid.Canvas path_canvas the canvas containing the main edge line segments.
---@return dotfiles.mermaid.Canvas box_start_canvas the canvas containing the source box junction glyph, when needed.
---@return dotfiles.mermaid.Canvas arrow_end_canvas the canvas containing the arrowhead at the target end.
---@return dotfiles.mermaid.Canvas arrow_start_canvas the canvas containing the optional arrowhead at the source end.
---@return dotfiles.mermaid.Canvas corners_canvas the canvas containing corner glyph overlays for the edge path.
---@return dotfiles.mermaid.Canvas label_canvas the canvas containing the edge label overlay.
local function draw_arrow(graph, base_canvas, edge)
  local path = edge.draw_path or edge.path
  if #path == 0 then
    local empty = canvas.copy_canvas(base_canvas)
    return empty, empty, empty, empty, empty, empty
  end

  local label_canvas = draw_arrow_label(graph, edge)
  local path_canvas, lines_drawn, directions = draw_path(graph, base_canvas, edge)
  local box_start_canvas = draw_box_start(graph, base_canvas, edge, path, lines_drawn[1] or {})
  local clips_through_side_boundary = (
    edge.source_composite_id
    and (
      geometry.same_direction(edge.start_dir, Directions.left)
      or geometry.same_direction(edge.start_dir, Directions.right)
    )
  )
    or (
      edge.target_composite_id
      and (
        geometry.same_direction(edge.end_dir, Directions.left)
        or geometry.same_direction(edge.end_dir, Directions.right)
      )
    )
  local should_draw_end_arrow = edge.has_arrow_end and not clips_through_side_boundary
  local arrow_end_canvas = should_draw_end_arrow
      and draw_arrow_head(base_canvas, lines_drawn[#lines_drawn] or {}, directions[#directions] or edge.end_dir)
    or (
      (edge.source_composite_id and clips_through_side_boundary and edge.text ~= "")
        and draw_box_end(graph, base_canvas, edge)
      or canvas.copy_canvas(base_canvas)
    )

  local arrow_start_canvas = canvas.copy_canvas(base_canvas)
  if edge.has_arrow_start and #lines_drawn > 0 then
    local first_line = lines_drawn[1]
    local first_point = first_line[1]
    local start_direction = geometry.opposite_direction(directions[1])
    local arrow_position = { x = first_point.x, y = first_point.y }
    if geometry.same_direction(directions[1], Directions.right) then
      arrow_position.x = first_point.x - 1
    elseif geometry.same_direction(directions[1], Directions.left) then
      arrow_position.x = first_point.x + 1
    elseif geometry.same_direction(directions[1], Directions.down) then
      arrow_position.y = first_point.y - 1
    elseif geometry.same_direction(directions[1], Directions.up) then
      arrow_position.y = first_point.y + 1
    end
    arrow_start_canvas = draw_arrow_head(base_canvas, { first_point, arrow_position }, start_direction)
  end

  local corners_canvas = draw_corners(graph, base_canvas, path)
  return path_canvas, box_start_canvas, arrow_end_canvas, arrow_start_canvas, corners_canvas, label_canvas
end

---Draw the private segment that connects one bundled edge to its shared junction.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides routing coordinates.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy for each bundled-edge overlay.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the bundled edge whose private branch segment should be rendered.
---@param bundle dotfiles.mermaid.graph_renderer.EdgeBundle the bundle metadata shared by related edges.
---@return dotfiles.mermaid.Canvas path_canvas the canvas containing the branch path from the node to the bundle junction.
---@return dotfiles.mermaid.Canvas box_start_canvas the canvas containing the source box junction glyph for the branch, when needed.
---@return dotfiles.mermaid.Canvas arrow_end_canvas an empty canvas placeholder for compatibility with the standard edge overlay shape.
---@return dotfiles.mermaid.Canvas arrow_start_canvas an empty canvas placeholder for compatibility with the standard edge overlay shape.
---@return dotfiles.mermaid.Canvas corners_canvas the canvas containing corner glyph overlays for the branch path.
---@return dotfiles.mermaid.Canvas label_canvas an empty canvas placeholder because bundled branches do not draw labels here.
local function draw_bundled_edge_segment(graph, base_canvas, edge, bundle)
  local empty = canvas.copy_canvas(base_canvas)
  if not edge.path_to_junction or #edge.path_to_junction == 0 then
    return empty, empty, empty, empty, empty, empty
  end

  local path_canvas = canvas.copy_canvas(base_canvas)
  local drawing_path = {}
  for index, grid_coord in ipairs(edge.path_to_junction) do
    if bundle.type == "fan-in" and index == 1 then
      drawing_path[index] = layout.node_attachment_point(graph, edge.from, edge.start_dir)
    elseif bundle.type == "fan-out" and index == #edge.path_to_junction then
      drawing_path[index] = layout.node_attachment_point(graph, edge.to, edge.end_dir)
    else
      drawing_path[index] = layout.grid_to_drawing_coord(graph, grid_coord)
    end
  end

  for index = 2, #drawing_path do
    if not geometry.same_drawing_coord(drawing_path[index - 1], drawing_path[index]) then
      draw_line(path_canvas, drawing_path[index - 1], drawing_path[index], 1, -1, edge.style)
    end
  end

  local corners_canvas = draw_corners(graph, base_canvas, assert(edge.path_to_junction))

  local box_start_canvas = canvas.copy_canvas(base_canvas)
  if bundle.type == "fan-in" and #edge.path_to_junction >= 2 then
    local first_point = drawing_path[1]
    local direction = geometry.determine_direction(edge.path_to_junction[1], edge.path_to_junction[2])
    if geometry.same_direction(direction, Directions.up) then
      box_start_canvas[first_point.x][first_point.y] = "┴"
    elseif geometry.same_direction(direction, Directions.down) then
      box_start_canvas[first_point.x][first_point.y] = "┬"
    elseif geometry.same_direction(direction, Directions.left) then
      box_start_canvas[first_point.x][first_point.y] = "┤"
    elseif geometry.same_direction(direction, Directions.right) then
      box_start_canvas[first_point.x][first_point.y] = "├"
    end
  end

  return path_canvas, box_start_canvas, empty, empty, corners_canvas, empty
end

---Draw the shared trunk path used by all edges in a bundle.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides routing coordinates.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy before drawing the shared path.
---@param bundle dotfiles.mermaid.graph_renderer.EdgeBundle the bundle whose shared trunk path should be rendered.
---@return dotfiles.mermaid.Canvas path_canvas a canvas containing the shared bundle path segments.
---@return dotfiles.mermaid.Canvas corners_canvas a canvas containing corner glyph overlays for the shared path.
local function draw_bundle_shared_path(graph, base_canvas, bundle)
  local path_canvas = canvas.copy_canvas(base_canvas)
  local corners_canvas = canvas.copy_canvas(base_canvas)
  if #bundle.shared_path < 2 then
    return path_canvas, corners_canvas
  end

  local drawing_path = {}
  for index, grid_coord in ipairs(bundle.shared_path) do
    if bundle.type == "fan-in" and index == #bundle.shared_path then
      drawing_path[index] = layout.node_attachment_point(graph, bundle.shared_node, Directions.up)
    elseif bundle.type == "fan-out" and index == 1 then
      drawing_path[index] = layout.node_attachment_point(graph, bundle.shared_node, Directions.down)
    else
      drawing_path[index] = layout.grid_to_drawing_coord(graph, grid_coord)
    end
  end

  for index = 2, #drawing_path do
    if not geometry.same_drawing_coord(drawing_path[index - 1], drawing_path[index]) then
      draw_line(path_canvas, drawing_path[index - 1], drawing_path[index], 1, -1, bundle.edges[1].style)
    end
  end

  corners_canvas = draw_corners(graph, base_canvas, bundle.shared_path)
  return path_canvas, corners_canvas
end

---Draw the arrowhead where a bundled fan-in trunk reaches its shared target node.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy before placing the bundle arrowhead.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides the target attachment point.
---@param bundle dotfiles.mermaid.graph_renderer.EdgeBundle the fan-in bundle whose shared trunk ends at the target node.
---@return dotfiles.mermaid.Canvas arrow_canvas a canvas containing the bundle arrowhead overlay.
local function draw_bundle_arrowhead(base_canvas, graph, bundle)
  local arrow_canvas = canvas.copy_canvas(base_canvas)
  if #bundle.shared_path < 2 then
    return arrow_canvas
  end

  local last_direction =
    geometry.determine_direction(bundle.shared_path[#bundle.shared_path - 1], bundle.shared_path[#bundle.shared_path])
  local position = layout.node_attachment_point(graph, bundle.shared_node, Directions.up)
  position.y = position.y - 1
  arrow_canvas[position.x][position.y] = arrowhead_glyph(last_direction)
  return arrow_canvas
end

---Draw the arrowhead where a bundled fan-out branch reaches its destination node.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy before placing the branch arrowhead.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides the target attachment point.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the bundled fan-out edge whose destination arrowhead should be rendered.
---@return dotfiles.mermaid.Canvas arrow_canvas a canvas containing the branch arrowhead overlay.
local function draw_bundled_edge_arrowhead(base_canvas, graph, edge)
  local arrow_canvas = canvas.copy_canvas(base_canvas)
  if not edge.path_to_junction or #edge.path_to_junction < 2 then
    return arrow_canvas
  end

  local last_direction = geometry.determine_direction(
    edge.path_to_junction[#edge.path_to_junction - 1],
    edge.path_to_junction[#edge.path_to_junction]
  )
  local position = layout.node_attachment_point(graph, edge.to, Directions.up)
  position.y = position.y - 1
  arrow_canvas[position.x][position.y] = arrowhead_glyph(last_direction)
  return arrow_canvas
end

---Draw the junction glyph for a bundle based on every connected arrival and departure.
---@param base_canvas dotfiles.mermaid.Canvas the base canvas to copy before placing the junction glyph.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides the junction drawing coordinate.
---@param bundle dotfiles.mermaid.graph_renderer.EdgeBundle the bundle whose junction connectivity determines the glyph.
---@return dotfiles.mermaid.Canvas junction_canvas a canvas containing the bundle junction glyph overlay.
local function draw_junction_character(base_canvas, graph, bundle)
  local junction_canvas = canvas.copy_canvas(base_canvas)
  if not bundle.junction_point then
    return junction_canvas
  end

  local drawing_coord = layout.grid_to_drawing_coord(graph, bundle.junction_point)
  local has_up, has_down, has_left, has_right = false, false, false, false

  if #bundle.shared_path >= 2 then
    local junction_index = bundle.type == "fan-in" and 1 or #bundle.shared_path
    local adjacent_index = bundle.type == "fan-in" and 2 or (#bundle.shared_path - 1)
    local shared_direction =
      geometry.determine_direction(bundle.shared_path[junction_index], bundle.shared_path[adjacent_index])
    if geometry.same_direction(shared_direction, Directions.down) then
      has_down = true
    elseif geometry.same_direction(shared_direction, Directions.up) then
      has_up = true
    elseif geometry.same_direction(shared_direction, Directions.right) then
      has_right = true
    elseif geometry.same_direction(shared_direction, Directions.left) then
      has_left = true
    end
  end

  for _, edge in ipairs(bundle.edges) do
    if edge.path_to_junction and #edge.path_to_junction >= 2 then
      local junction_index = bundle.type == "fan-in" and #edge.path_to_junction or 1
      local adjacent_index = bundle.type == "fan-in" and (#edge.path_to_junction - 1) or 2
      local arrival_direction =
        geometry.determine_direction(edge.path_to_junction[adjacent_index], edge.path_to_junction[junction_index])
      if geometry.same_direction(arrival_direction, Directions.down) then
        has_up = true
      elseif geometry.same_direction(arrival_direction, Directions.up) then
        has_down = true
      elseif geometry.same_direction(arrival_direction, Directions.right) then
        has_left = true
      elseif geometry.same_direction(arrival_direction, Directions.left) then
        has_right = true
      end
    end
  end

  local char = "┼"
  if has_down and has_left and has_right and not has_up then
    char = "┬"
  elseif has_up and has_left and has_right and not has_down then
    char = "┴"
  elseif has_up and has_down and has_right and not has_left then
    char = "├"
  elseif has_up and has_down and has_left and not has_right then
    char = "┤"
  elseif has_left and has_right and not (has_up or has_down) then
    char = "─"
  elseif has_up and has_down and not (has_left or has_right) then
    char = "│"
  elseif has_down and has_right then
    char = "┌"
  elseif has_down and has_left then
    char = "┐"
  elseif has_up and has_right then
    char = "└"
  elseif has_up and has_left then
    char = "┘"
  end

  junction_canvas[drawing_coord.x][drawing_coord.y] = char
  return junction_canvas
end

---Draw the border box for a rendered subgraph or region.
---@param subgraph dotfiles.mermaid.graph_renderer.LayoutSubgraph the subgraph whose bounding box should be rendered.
---@return dotfiles.mermaid.Canvas subgraph_canvas a canvas containing the subgraph border glyphs.
local function draw_subgraph_box(subgraph)
  local width = subgraph.max_x - subgraph.min_x
  local height = subgraph.max_y - subgraph.min_y
  if width <= 0 or height <= 0 then
    return canvas.mk_canvas(0, 0)
  end

  local subgraph_canvas = canvas.mk_canvas(width, height)
  local h_char = subgraph.kind == "region" and "┄" or "─"
  local v_char = subgraph.kind == "region" and "┆" or "│"

  for x = 1, width - 1 do
    subgraph_canvas[x][0] = h_char
    subgraph_canvas[x][height] = h_char
  end
  for y = 1, height - 1 do
    subgraph_canvas[0][y] = v_char
    subgraph_canvas[width][y] = v_char
  end
  subgraph_canvas[0][0] = "┌"
  subgraph_canvas[width][0] = "┐"
  subgraph_canvas[0][height] = "└"
  subgraph_canvas[width][height] = "┘"
  return subgraph_canvas
end

---Draw a subgraph label and return the graph-space offset where it should be merged.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that owns the subgraph.
---@param subgraph dotfiles.mermaid.graph_renderer.LayoutSubgraph the subgraph whose label text should be rendered.
---@return dotfiles.mermaid.Canvas label_canvas a canvas containing the subgraph label text.
---@return dotfiles.mermaid.graph_renderer.DrawingCoord offset the graph-space coordinate where the label canvas should be merged.
local function draw_subgraph_label(graph, subgraph)
  local width = subgraph.max_x - subgraph.min_x
  local height = subgraph.max_y - subgraph.min_y
  if width <= 0 or height <= 0 or subgraph.name == "" then
    return canvas.mk_canvas(0, 0), { x = 0, y = 0 }
  end

  local label_canvas = canvas.mk_canvas(width, height)
  for index, line in ipairs(text.split_lines(subgraph.name)) do
    local line_width = text.char_len(line)
    local label_x = (graph.config.graph_direction == "LR" and subgraph.kind == nil)
        and math.ceil((width - line_width) / 2)
      or math.floor((width - line_width) / 2)
    if label_x < 1 then
      label_x = 1
    end
    canvas.draw_text(label_canvas, { x = label_x, y = index }, line, true)
  end

  return label_canvas, { x = subgraph.min_x, y = subgraph.min_y }
end

---Draw a state note box and place each note line inside it.
---@param note dotfiles.mermaid.graph_renderer.LayoutNote the note whose box and text should be rendered.
---@return dotfiles.mermaid.Canvas note_canvas a canvas containing the rendered note box and text.
local function draw_state_note_box(note)
  local note_width = assert(note.width, "note width must be computed during layout")
  local note_height = assert(note.height, "note height must be computed during layout")
  local note_canvas = canvas.mk_canvas(note_width - 1, note_height - 1)

  for x = 1, note_width - 2 do
    note_canvas[x][0] = "─"
    note_canvas[x][note_height - 1] = "─"
  end
  for y = 1, note_height - 2 do
    note_canvas[0][y] = "│"
    note_canvas[note_width - 1][y] = "│"
  end
  note_canvas[0][0] = "┌"
  note_canvas[note_width - 1][0] = "┐"
  note_canvas[0][note_height - 1] = "└"
  note_canvas[note_width - 1][note_height - 1] = "┘"

  for index, note_line in ipairs(text.split_lines(note.text)) do
    canvas.draw_text(note_canvas, { x = 2, y = index }, note_line, true)
  end

  return note_canvas
end

---Draw the dotted connector that ties a state note back to its node.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the laid out graph that provides node sizing and canvas bounds.
---@param note dotfiles.mermaid.graph_renderer.LayoutNote the note whose connector path should be rendered.
---@return dotfiles.mermaid.Canvas connector_canvas a canvas containing the dotted connector overlay, or an empty canvas when no connector is needed.
local function draw_state_note_connector(graph, note)
  local connector_canvas = canvas.mk_canvas(graph.canvas_max_x, graph.canvas_max_y)
  local note_offset = note.offset
  local note_width = note.width
  local note_height = note.height
  local node_coord = note.node.drawing_coord
  if not note_offset or not note_width or not note_height or not node_coord then
    return connector_canvas
  end

  local node_size = layout.node_render_size(graph, note.node)
  local start_y = note_offset.y + math.floor(note_height / 2)
  local start_x = note.position == "left" and (note_offset.x + note_width - 1) or note_offset.x
  local target_x = node_coord.x + math.floor(node_size.width / 2)
  local target_y = node_coord.y

  if start_x == target_x or target_y <= start_y then
    return connector_canvas
  end

  local step = start_x < target_x and 1 or -1
  for x = start_x + step, target_x - step, step do
    connector_canvas[x][start_y] = "┄"
  end

  for y = start_y + 1, target_y - 1 do
    connector_canvas[target_x][y] = "┆"
  end

  connector_canvas[start_x][start_y] = note.position == "left" and "├" or "┤"
  connector_canvas[target_x][start_y] = start_x < target_x and "┐" or "┌"
  return connector_canvas
end

---Render the full layout graph by layering subgraphs, nodes, edges, labels, and notes.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the fully prepared layout graph to render.
---@return dotfiles.mermaid.Canvas target_canvas the merged canvas for the entire rendered graph.
local function draw_graph(graph)
  local target_canvas = canvas.mk_canvas(graph.canvas_max_x, graph.canvas_max_y)

  local sorted_subgraphs = {}
  for _, subgraph in ipairs(graph.subgraphs) do
    sorted_subgraphs[#sorted_subgraphs + 1] = subgraph
  end
  table.sort(sorted_subgraphs, function(left, right)
    return left.depth < right.depth
  end)

  for _, subgraph in ipairs(sorted_subgraphs) do
    target_canvas = canvas.merge_canvases(
      target_canvas,
      { x = subgraph.min_x, y = subgraph.min_y },
      { draw_subgraph_box(subgraph) }
    )
  end

  for _, node in ipairs(graph.nodes) do
    if node.drawing_coord then
      target_canvas = canvas.merge_canvases(target_canvas, node.drawing_coord, { draw_node_canvas(graph, node) })
    end
  end

  local base_canvas = target_canvas
  local line_canvases = {}
  local corner_canvases = {}
  local arrow_end_canvases = {}
  local arrow_start_canvases = {}
  local box_start_canvases = {}
  local label_canvases = {}
  local junction_canvases = {}
  local processed_bundles = {}

  for _, edge in ipairs(graph.edges) do
    if edge.bundle and edge.path_to_junction then
      local path_canvas, box_start_canvas, _, _, corners_canvas, label_canvas =
        draw_bundled_edge_segment(graph, base_canvas, edge, edge.bundle)
      line_canvases[#line_canvases + 1] = path_canvas
      corner_canvases[#corner_canvases + 1] = corners_canvas
      box_start_canvases[#box_start_canvases + 1] = box_start_canvas
      label_canvases[#label_canvases + 1] = label_canvas

      if not processed_bundles[edge.bundle] then
        processed_bundles[edge.bundle] = true
        local shared_path_canvas, shared_corners_canvas = draw_bundle_shared_path(graph, base_canvas, edge.bundle)
        line_canvases[#line_canvases + 1] = shared_path_canvas
        corner_canvases[#corner_canvases + 1] = shared_corners_canvas
        if edge.bundle.type == "fan-in" then
          arrow_end_canvases[#arrow_end_canvases + 1] = draw_bundle_arrowhead(base_canvas, graph, edge.bundle)
        end
        junction_canvases[#junction_canvases + 1] = draw_junction_character(base_canvas, graph, edge.bundle)
      end

      if edge.bundle.type == "fan-out" and edge.has_arrow_end then
        arrow_end_canvases[#arrow_end_canvases + 1] = draw_bundled_edge_arrowhead(base_canvas, graph, edge)
      end
    else
      local path_canvas, box_start_canvas, arrow_end_canvas, arrow_start_canvas, corners_canvas, label_canvas =
        draw_arrow(graph, base_canvas, edge)
      line_canvases[#line_canvases + 1] = path_canvas
      corner_canvases[#corner_canvases + 1] = corners_canvas
      arrow_end_canvases[#arrow_end_canvases + 1] = arrow_end_canvas
      arrow_start_canvases[#arrow_start_canvases + 1] = arrow_start_canvas
      box_start_canvases[#box_start_canvases + 1] = box_start_canvas
      label_canvases[#label_canvases + 1] = label_canvas
    end
  end

  if #line_canvases > 0 then
    target_canvas = canvas.merge_canvases(target_canvas, { x = 0, y = 0 }, line_canvases)
  end
  if #corner_canvases > 0 then
    target_canvas = canvas.merge_canvases(target_canvas, { x = 0, y = 0 }, corner_canvases)
  end
  if #junction_canvases > 0 then
    target_canvas = canvas.merge_canvases(target_canvas, { x = 0, y = 0 }, junction_canvases)
  end
  if #arrow_end_canvases > 0 then
    target_canvas = canvas.merge_canvases(target_canvas, { x = 0, y = 0 }, arrow_end_canvases)
  end
  if #box_start_canvases > 0 then
    target_canvas = canvas.merge_canvases(target_canvas, { x = 0, y = 0 }, box_start_canvases)
  end
  if #arrow_start_canvases > 0 then
    target_canvas = canvas.merge_canvases(target_canvas, { x = 0, y = 0 }, arrow_start_canvases)
  end
  if #label_canvases > 0 then
    target_canvas = canvas.merge_canvases(target_canvas, { x = 0, y = 0 }, label_canvases)
  end

  for _, subgraph in ipairs(graph.subgraphs) do
    if #subgraph.nodes > 0 then
      local label_canvas, offset = draw_subgraph_label(graph, subgraph)
      target_canvas = canvas.merge_canvases(target_canvas, offset, { label_canvas })
    end
  end

  for _, note in ipairs(graph.notes) do
    if note.offset then
      target_canvas = canvas.merge_canvases(target_canvas, note.offset, { draw_state_note_box(note) })
      target_canvas = canvas.merge_canvases(target_canvas, { x = 0, y = 0 }, { draw_state_note_connector(graph, note) })
    end
  end

  return target_canvas
end

---Trim blank lines from the top and bottom of the rendered output.
---@param lines string[] the rendered text lines before outer blank-margin trimming.
---@return string[] trimmed the rendered lines with leading and trailing blank lines removed.
local function trim_empty_margin_lines(lines)
  local start_index = 1
  while start_index <= #lines and lines[start_index] == "" do
    start_index = start_index + 1
  end

  local end_index = #lines
  while end_index >= start_index and lines[end_index] == "" do
    end_index = end_index - 1
  end

  local trimmed = {}
  for index = start_index, end_index do
    trimmed[#trimmed + 1] = lines[index]
  end
  return trimmed
end

---Render a laid out graph into final text lines, including bottom-to-top flipping.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the fully prepared layout graph to convert into text lines.
---@return string[] lines the final rendered text lines for the graph.
local function render(graph)
  if #graph.nodes == 0 then
    return {}
  end

  local rendered_canvas = draw_graph(graph)
  if graph.parsed_direction == "BT" then
    canvas.flip_canvas_vertically(rendered_canvas)
  end
  return trim_empty_margin_lines(canvas.canvas_to_lines(rendered_canvas))
end

local M = {}
M.render = render
return M
