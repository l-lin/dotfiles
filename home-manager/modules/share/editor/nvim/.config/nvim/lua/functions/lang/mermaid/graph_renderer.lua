local canvas = require("functions.lang.mermaid.canvas")
local text = require("functions.lang.mermaid.text")

local Up = { name = "up", x = 1, y = 0 }
local Down = { name = "down", x = 1, y = 2 }
local Left = { name = "left", x = 0, y = 1 }
local Right = { name = "right", x = 2, y = 1 }
local UpperRight = { name = "upper_right", x = 2, y = 0 }
local UpperLeft = { name = "upper_left", x = 0, y = 0 }
local LowerRight = { name = "lower_right", x = 2, y = 2 }
local LowerLeft = { name = "lower_left", x = 0, y = 2 }
local Middle = { name = "middle", x = 1, y = 1 }

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

local LINE_CHARS = {
  solid = { h = "─", v = "│" },
  dotted = { h = "┄", v = "┆" },
  thick = { h = "━", v = "┃" },
}

local function direction_eq(left, right)
  return left == right or (left and right and left.x == right.x and left.y == right.y)
end

local function grid_key(coord)
  return string.format("%d,%d", coord.x, coord.y)
end

local function grid_coord_direction(coord, direction)
  return {
    x = coord.x + direction.x,
    y = coord.y + direction.y,
  }
end

local function grid_coord_equals(left, right)
  return left.x == right.x and left.y == right.y
end

local function drawing_coord_equals(left, right)
  return left.x == right.x and left.y == right.y
end

local function determine_direction(from, to)
  if from.x == to.x then
    return from.y < to.y and Down or Up
  end
  if from.y == to.y then
    return from.x < to.x and Right or Left
  end
  if from.x < to.x then
    return from.y < to.y and LowerRight or UpperRight
  end
  return from.y < to.y and LowerLeft or UpperLeft
end

local function get_opposite(direction)
  if direction_eq(direction, Up) then
    return Down
  end
  if direction_eq(direction, Down) then
    return Up
  end
  if direction_eq(direction, Left) then
    return Right
  end
  if direction_eq(direction, Right) then
    return Left
  end
  if direction_eq(direction, UpperRight) then
    return LowerLeft
  end
  if direction_eq(direction, UpperLeft) then
    return LowerRight
  end
  if direction_eq(direction, LowerRight) then
    return UpperLeft
  end
  if direction_eq(direction, LowerLeft) then
    return UpperRight
  end
  return Middle
end

local function get_corners(shape)
  return SHAPE_CORNERS[shape] or SHAPE_CORNERS.rectangle
end

local function get_box_dimensions(label, padding)
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

local function get_shape_dimensions(shape, label, padding)
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

  if shape == "state-start" or shape == "state-end" then
    return {
      width = 5,
      height = 3,
      grid_columns = { 1, 3, 1 },
      grid_rows = { 1, 1, 1 },
    }
  end

  return get_box_dimensions(label, padding)
end

local function get_box_attachment_point(direction, dimensions, base_coord)
  local width = dimensions.width
  local height = dimensions.height
  local center_x = base_coord.x + math.floor(width / 2)
  local center_y = base_coord.y + math.floor(height / 2)

  if direction_eq(direction, Up) then
    return { x = center_x, y = base_coord.y }
  end
  if direction_eq(direction, Down) then
    return { x = center_x, y = base_coord.y + height - 1 }
  end
  if direction_eq(direction, Left) then
    return { x = base_coord.x, y = center_y }
  end
  if direction_eq(direction, Right) then
    return { x = base_coord.x + width - 1, y = center_y }
  end
  if direction_eq(direction, UpperLeft) then
    return { x = base_coord.x, y = base_coord.y }
  end
  if direction_eq(direction, UpperRight) then
    return { x = base_coord.x + width - 1, y = base_coord.y }
  end
  if direction_eq(direction, LowerLeft) then
    return { x = base_coord.x, y = base_coord.y + height - 1 }
  end
  if direction_eq(direction, LowerRight) then
    return { x = base_coord.x + width - 1, y = base_coord.y + height - 1 }
  end
  return { x = center_x, y = center_y }
end

local function get_shape_attachment_point(shape, direction, dimensions, base_coord)
  if shape == "state-start" or shape == "state-end" then
    local width = dimensions.width
    local height = dimensions.height
    local center_x = base_coord.x + math.floor(width / 2)
    local center_y = base_coord.y + math.floor(height / 2)

    if direction_eq(direction, Up) then
      return { x = center_x, y = base_coord.y }
    end
    if direction_eq(direction, Down) then
      return { x = center_x, y = base_coord.y + height - 1 }
    end
    if direction_eq(direction, Left) then
      return { x = base_coord.x, y = center_y }
    end
    if direction_eq(direction, Right) then
      return { x = base_coord.x + width - 1, y = center_y }
    end
    return { x = center_x, y = center_y }
  end

  return get_box_attachment_point(direction, dimensions, base_coord)
end

local function draw_centered_lines(box, width, height, label)
  local lines = text.split_label_lines(label)
  local center_y = math.floor((height - 1) / 2)
  local start_y = center_y - math.floor((#lines - 1) / 2)

  for line_index, line in ipairs(lines) do
    local line_width = text.char_len(line)
    local text_x = math.floor((width - 1) / 2) - math.ceil(line_width / 2) + 1
    canvas.draw_text(box, { x = text_x, y = start_y + line_index - 1 }, line, true)
  end
end

local function draw_node(node, graph)
  local grid_coord = node.grid_coord
  local width = (graph.column_width[grid_coord.x] or 0) + (graph.column_width[grid_coord.x + 1] or 0)
  local height = (graph.row_height[grid_coord.y] or 0) + (graph.row_height[grid_coord.y + 1] or 0)
  local box = canvas.mk_canvas(math.max(width, 0), math.max(height, 0))
  local corners = get_corners(node.shape)
  local h_char = node.shape == "state-end" and "═" or "─"
  local v_char = node.shape == "state-end" and "║" or "│"
  local max_x = width
  local max_y = height

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

  draw_centered_lines(box, width + 1, height + 1, node.display_label)
  return box
end

local function convert_subgraph(parsed_subgraph, parent, node_map, all_subgraphs)
  local direction = nil
  if parsed_subgraph.direction then
    if parsed_subgraph.direction == "LR" or parsed_subgraph.direction == "RL" then
      direction = "LR"
    else
      direction = "TD"
    end
  end

  local subgraph = {
    name = parsed_subgraph.label,
    nodes = {},
    parent = parent,
    children = {},
    min_x = 0,
    min_y = 0,
    max_x = 0,
    max_y = 0,
    direction = direction,
  }

  for _, node_id in ipairs(parsed_subgraph.node_ids) do
    local node = node_map[node_id]
    if node then
      subgraph.nodes[#subgraph.nodes + 1] = node
    end
  end

  all_subgraphs[#all_subgraphs + 1] = subgraph

  for _, child_parsed_subgraph in ipairs(parsed_subgraph.children) do
    local child = convert_subgraph(child_parsed_subgraph, subgraph, node_map, all_subgraphs)
    subgraph.children[#subgraph.children + 1] = child

    for _, child_node in ipairs(child.nodes) do
      local seen = false
      for _, existing_node in ipairs(subgraph.nodes) do
        if existing_node == child_node then
          seen = true
          break
        end
      end
      if not seen then
        subgraph.nodes[#subgraph.nodes + 1] = child_node
      end
    end
  end

  return subgraph
end

local function is_ancestor_or_self(candidate, target)
  local current = target
  while current do
    if current == candidate then
      return true
    end
    current = current.parent
  end
  return false
end

local function build_subgraph_map(parsed_subgraphs, ascii_subgraphs, result)
  local flattened = {}

  local function flatten(subgraphs)
    for _, subgraph in ipairs(subgraphs) do
      flattened[#flattened + 1] = subgraph
      flatten(subgraph.children)
    end
  end

  flatten(parsed_subgraphs)

  for index = 1, math.min(#flattened, #ascii_subgraphs) do
    result[flattened[index]] = ascii_subgraphs[index]
  end
end

local function deduplicate_subgraph_nodes(parsed_subgraphs, ascii_subgraphs, node_map)
  local subgraph_map = {}
  build_subgraph_map(parsed_subgraphs, ascii_subgraphs, subgraph_map)
  local node_owner = {}

  local function claim_nodes(parsed_subgraph)
    local ascii_subgraph = subgraph_map[parsed_subgraph]
    if not ascii_subgraph then
      return
    end

    for _, child in ipairs(parsed_subgraph.children) do
      claim_nodes(child)
    end

    for _, node_id in ipairs(parsed_subgraph.node_ids) do
      if not node_owner[node_id] then
        node_owner[node_id] = ascii_subgraph
      end
    end
  end

  for _, parsed_subgraph in ipairs(parsed_subgraphs) do
    claim_nodes(parsed_subgraph)
  end

  for _, ascii_subgraph in ipairs(ascii_subgraphs) do
    local deduplicated = {}
    for _, node in ipairs(ascii_subgraph.nodes) do
      local owner = node_owner[node.name]
      if not owner or is_ancestor_or_self(ascii_subgraph, owner) then
        deduplicated[#deduplicated + 1] = node
      end
    end
    ascii_subgraph.nodes = deduplicated
  end
end

local function convert_graph(parsed)
  local node_map = {}
  local nodes = {}

  for _, node_id in ipairs(parsed.node_order) do
    local parsed_node = parsed.nodes[node_id]
    if parsed_node then
      local node = {
        name = node_id,
        display_label = parsed_node.label,
        shape = parsed_node.shape,
        index = #nodes + 1,
        grid_coord = nil,
        drawing_coord = nil,
        drawing = nil,
        drawn = false,
      }
      node_map[node_id] = node
      nodes[#nodes + 1] = node
    end
  end

  local edges = {}
  for _, parsed_edge in ipairs(parsed.edges) do
    local from = node_map[parsed_edge.source]
    local to = node_map[parsed_edge.target]
    if from and to then
      edges[#edges + 1] = {
        from = from,
        to = to,
        text = parsed_edge.label or "",
        path = {},
        label_line = {},
        start_dir = Middle,
        end_dir = Middle,
        style = parsed_edge.style,
        has_arrow_start = parsed_edge.has_arrow_start,
        has_arrow_end = parsed_edge.has_arrow_end,
      }
    end
  end

  local subgraphs = {}
  for _, parsed_subgraph in ipairs(parsed.subgraphs) do
    convert_subgraph(parsed_subgraph, nil, node_map, subgraphs)
  end
  deduplicate_subgraph_nodes(parsed.subgraphs, subgraphs, node_map)

  return {
    nodes = nodes,
    edges = edges,
    canvas = canvas.mk_canvas(0, 0),
    grid = {},
    column_width = {},
    row_height = {},
    subgraphs = subgraphs,
    config = {
      padding_x = 5,
      padding_y = 5,
      box_border_padding = 1,
      graph_direction = (parsed.direction == "LR" or parsed.direction == "RL") and "LR" or "TD",
    },
    offset_x = 0,
    offset_y = 0,
    bundles = {},
    parsed_direction = parsed.direction,
  }
end

local function get_node_subgraph(graph, node)
  local innermost = nil
  for _, subgraph in ipairs(graph.subgraphs) do
    for _, candidate in ipairs(subgraph.nodes) do
      if candidate == node then
        if not innermost or is_ancestor_or_self(innermost, subgraph) then
          innermost = subgraph
        end
        break
      end
    end
  end
  return innermost
end

local function get_effective_direction(graph, node)
  local subgraph = get_node_subgraph(graph, node)
  if subgraph and subgraph.direction then
    return subgraph.direction
  end
  return graph.config.graph_direction
end

local function reserve_spot_in_grid(graph, node, requested, effective_direction)
  local direction = effective_direction or get_effective_direction(graph, node)

  if graph.grid[grid_key(requested)] then
    if direction == "LR" then
      return reserve_spot_in_grid(graph, node, { x = requested.x, y = requested.y + 4 }, direction)
    end
    return reserve_spot_in_grid(graph, node, { x = requested.x + 4, y = requested.y }, direction)
  end

  for dx = 0, 2 do
    for dy = 0, 2 do
      graph.grid[grid_key({ x = requested.x + dx, y = requested.y + dy })] = node
    end
  end

  node.grid_coord = requested
  return requested
end

local function node_in_subgraph(graph, node)
  return get_node_subgraph(graph, node) ~= nil
end

local function has_incoming_edge_from_outside_subgraph(graph, node)
  local node_subgraph = get_node_subgraph(graph, node)
  if not node_subgraph then
    return false
  end

  local has_external_edge = false
  for _, edge in ipairs(graph.edges) do
    if edge.to == node then
      local source_subgraph = get_node_subgraph(graph, edge.from)
      if source_subgraph ~= node_subgraph then
        has_external_edge = true
        break
      end
    end
  end

  if not has_external_edge then
    return false
  end

  for _, other_node in ipairs(node_subgraph.nodes) do
    if other_node ~= node and other_node.grid_coord then
      local other_external = false
      for _, edge in ipairs(graph.edges) do
        if edge.to == other_node then
          local source_subgraph = get_node_subgraph(graph, edge.from)
          if source_subgraph ~= node_subgraph then
            other_external = true
            break
          end
        end
      end
      if other_external and other_node.grid_coord.y < node.grid_coord.y then
        return false
      end
    end
  end

  return true
end

local function set_column_width(graph, node)
  local dimensions = get_shape_dimensions(node.shape, node.display_label, graph.config.box_border_padding)
  local grid_coord = node.grid_coord

  for offset = 0, 2 do
    local x = grid_coord.x + offset
    graph.column_width[x] = math.max(graph.column_width[x] or 0, dimensions.grid_columns[offset + 1])
    local y = grid_coord.y + offset
    graph.row_height[y] = math.max(graph.row_height[y] or 0, dimensions.grid_rows[offset + 1])
  end

  if grid_coord.x > 0 then
    graph.column_width[grid_coord.x - 1] = math.max(graph.column_width[grid_coord.x - 1] or 0, graph.config.padding_x)
  end

  if grid_coord.y > 0 then
    local padding = graph.config.padding_y
    if has_incoming_edge_from_outside_subgraph(graph, node) then
      padding = padding + 4
    end
    graph.row_height[grid_coord.y - 1] = math.max(graph.row_height[grid_coord.y - 1] or 0, padding)
  end
end

local function increase_grid_size_for_path(graph, path)
  for _, coord in ipairs(path) do
    if graph.column_width[coord.x] == nil then
      graph.column_width[coord.x] = math.floor(graph.config.padding_x / 2)
    end
    if graph.row_height[coord.y] == nil then
      graph.row_height[coord.y] = math.floor(graph.config.padding_y / 2)
    end
  end
end

local function get_edges_from_node(graph, node)
  local edges = {}
  for _, edge in ipairs(graph.edges) do
    if edge.from == node then
      edges[#edges + 1] = edge
    end
  end
  return edges
end

local function get_children(graph, node)
  local children = {}
  for _, edge in ipairs(get_edges_from_node(graph, node)) do
    children[#children + 1] = edge.to
  end
  return children
end

local MinHeap = {}
MinHeap.__index = MinHeap

function MinHeap.new()
  return setmetatable({ items = {} }, MinHeap)
end

function MinHeap:push(item)
  local items = self.items
  items[#items + 1] = item
  local index = #items
  while index > 1 do
    local parent = math.floor(index / 2)
    if items[index].priority < items[parent].priority then
      items[index], items[parent] = items[parent], items[index]
      index = parent
    else
      break
    end
  end
end

function MinHeap:pop()
  local items = self.items
  if #items == 0 then
    return nil
  end

  local top = items[1]
  local last = table.remove(items)
  if #items > 0 then
    items[1] = last
    local index = 1
    while true do
      local smallest = index
      local left = index * 2
      local right = left + 1

      if left <= #items and items[left].priority < items[smallest].priority then
        smallest = left
      end
      if right <= #items and items[right].priority < items[smallest].priority then
        smallest = right
      end
      if smallest == index then
        break
      end
      items[index], items[smallest] = items[smallest], items[index]
      index = smallest
    end
  end

  return top
end

function MinHeap:length()
  return #self.items
end

local MOVE_DIRS = {
  { x = 1, y = 0 },
  { x = -1, y = 0 },
  { x = 0, y = 1 },
  { x = 0, y = -1 },
}

local function heuristic(left, right)
  local abs_x = math.abs(left.x - right.x)
  local abs_y = math.abs(left.y - right.y)
  if abs_x == 0 or abs_y == 0 then
    return abs_x + abs_y
  end
  return abs_x + abs_y + 1
end

local function is_free_in_grid(grid, coord)
  if coord.x < 0 or coord.y < 0 then
    return false
  end
  return grid[grid_key(coord)] == nil
end

local function get_path(grid, from, to)
  local priority_queue = MinHeap.new()
  priority_queue:push({ coord = from, priority = 0 })

  local cost_so_far = { [grid_key(from)] = 0 }
  local came_from = { [grid_key(from)] = false }

  while priority_queue:length() > 0 do
    local current = priority_queue:pop().coord
    if grid_coord_equals(current, to) then
      local path = {}
      local cursor = current
      while cursor do
        table.insert(path, 1, cursor)
        local previous = came_from[grid_key(cursor)]
        cursor = previous or nil
      end
      return path
    end

    local current_cost = cost_so_far[grid_key(current)]
    for _, movement in ipairs(MOVE_DIRS) do
      local next_coord = { x = current.x + movement.x, y = current.y + movement.y }
      if (not is_free_in_grid(grid, next_coord)) and not grid_coord_equals(next_coord, to) then
        goto continue
      end

      local new_cost = current_cost + 1
      local next_key = grid_key(next_coord)
      local existing_cost = cost_so_far[next_key]
      if existing_cost == nil or new_cost < existing_cost then
        cost_so_far[next_key] = new_cost
        priority_queue:push({
          coord = next_coord,
          priority = new_cost + heuristic(next_coord, to),
        })
        came_from[next_key] = current
      end

      ::continue::
    end
  end

  return nil
end

local function merge_path(path)
  if #path <= 2 then
    return path
  end

  local to_remove = {}
  local step0 = path[1]
  local step1 = path[2]

  for index = 3, #path do
    local step2 = path[index]
    local previous_dx = step1.x - step0.x
    local previous_dy = step1.y - step0.y
    local dx = step2.x - step1.x
    local dy = step2.y - step1.y

    if previous_dx == dx and previous_dy == dy then
      to_remove[index - 1] = true
    end

    step0 = step1
    step1 = step2
  end

  local merged = {}
  for index, coord in ipairs(path) do
    if not to_remove[index] then
      merged[#merged + 1] = coord
    end
  end
  return merged
end

local function self_reference_direction(graph_direction)
  if graph_direction == "LR" then
    return Right, Down, Down, Right
  end
  return Down, Right, Right, Down
end

local function determine_start_and_end_dir(edge, graph_direction)
  if edge.from == edge.to then
    return self_reference_direction(graph_direction)
  end

  local direction = determine_direction(edge.from.grid_coord, edge.to.grid_coord)
  local backwards = graph_direction == "LR"
      and (direction_eq(direction, Left) or direction_eq(direction, UpperLeft) or direction_eq(direction, LowerLeft))
    or graph_direction == "TD"
      and (direction_eq(direction, Up) or direction_eq(direction, UpperLeft) or direction_eq(direction, UpperRight))

  local preferred_dir, preferred_opposite, alternative_dir, alternative_opposite

  if direction_eq(direction, LowerRight) then
    if graph_direction == "LR" then
      preferred_dir, preferred_opposite = Down, Left
      alternative_dir, alternative_opposite = Right, Up
    else
      preferred_dir, preferred_opposite = Right, Up
      alternative_dir, alternative_opposite = Down, Left
    end
  elseif direction_eq(direction, UpperRight) then
    if graph_direction == "LR" then
      preferred_dir, preferred_opposite = Up, Left
      alternative_dir, alternative_opposite = Right, Down
    else
      preferred_dir, preferred_opposite = Right, Down
      alternative_dir, alternative_opposite = Up, Left
    end
  elseif direction_eq(direction, LowerLeft) then
    if graph_direction == "LR" then
      preferred_dir, preferred_opposite = Down, Down
      alternative_dir, alternative_opposite = Left, Up
    else
      preferred_dir, preferred_opposite = Left, Up
      alternative_dir, alternative_opposite = Down, Right
    end
  elseif direction_eq(direction, UpperLeft) then
    if graph_direction == "LR" then
      preferred_dir, preferred_opposite = Down, Down
      alternative_dir, alternative_opposite = Left, Down
    else
      preferred_dir, preferred_opposite = Right, Right
      alternative_dir, alternative_opposite = Up, Right
    end
  elseif backwards then
    if graph_direction == "LR" and direction_eq(direction, Left) then
      preferred_dir, preferred_opposite = Down, Down
      alternative_dir, alternative_opposite = Left, Right
    elseif graph_direction == "TD" and direction_eq(direction, Up) then
      preferred_dir, preferred_opposite = Right, Right
      alternative_dir, alternative_opposite = Up, Down
    else
      preferred_dir, preferred_opposite = direction, get_opposite(direction)
      alternative_dir, alternative_opposite = direction, get_opposite(direction)
    end
  else
    preferred_dir, preferred_opposite = direction, get_opposite(direction)
    alternative_dir, alternative_opposite = direction, get_opposite(direction)
  end

  return preferred_dir, preferred_opposite, alternative_dir, alternative_opposite
end

local function determine_path(graph, edge)
  local source_subgraph = get_node_subgraph(graph, edge.from)
  local target_subgraph = get_node_subgraph(graph, edge.to)
  local effective_direction = source_subgraph and source_subgraph == target_subgraph and source_subgraph.direction or graph.config.graph_direction
  local preferred_dir, preferred_opposite, alternative_dir, alternative_opposite = determine_start_and_end_dir(edge, effective_direction)

  local preferred_from = grid_coord_direction(edge.from.grid_coord, preferred_dir)
  local preferred_to = grid_coord_direction(edge.to.grid_coord, preferred_opposite)
  local preferred_path = get_path(graph.grid, preferred_from, preferred_to)

  local alternative_from = grid_coord_direction(edge.from.grid_coord, alternative_dir)
  local alternative_to = grid_coord_direction(edge.to.grid_coord, alternative_opposite)
  local alternative_path = get_path(graph.grid, alternative_from, alternative_to)

  if preferred_path and alternative_path then
    preferred_path = merge_path(preferred_path)
    alternative_path = merge_path(alternative_path)
    if #preferred_path <= #alternative_path then
      edge.start_dir = preferred_dir
      edge.end_dir = preferred_opposite
      edge.path = preferred_path
    else
      edge.start_dir = alternative_dir
      edge.end_dir = alternative_opposite
      edge.path = alternative_path
    end
    return
  end

  if preferred_path then
    edge.start_dir = preferred_dir
    edge.end_dir = preferred_opposite
    edge.path = merge_path(preferred_path)
    return
  end

  if alternative_path then
    edge.start_dir = alternative_dir
    edge.end_dir = alternative_opposite
    edge.path = merge_path(alternative_path)
    return
  end

  edge.start_dir = preferred_dir
  edge.end_dir = preferred_opposite
  edge.path = { preferred_from, preferred_to }
end

local function calculate_line_width(graph, line)
  local total = 0
  local start_x = math.min(line[1].x, line[2].x)
  local end_x = math.max(line[1].x, line[2].x)
  for x = start_x, end_x do
    total = total + (graph.column_width[x] or 0)
  end
  return total
end

local function determine_label_line(graph, edge)
  if edge.text == "" then
    return
  end

  local segments = {}
  for index = 2, #edge.path do
    local line = { edge.path[index - 1], edge.path[index] }
    segments[#segments + 1] = {
      line = line,
      width = calculate_line_width(graph, line),
      index = index,
    }
  end

  local suitable = {}
  for _, segment in ipairs(segments) do
    if segment.width >= text.char_len(edge.text) and segment.index > 2 then
      suitable[#suitable + 1] = segment
    end
  end

  table.sort(suitable, function(left, right)
    return left.index > right.index
  end)

  local chosen = suitable[1]
  if not chosen then
    local fallback = {}
    for _, segment in ipairs(segments) do
      if segment.width >= text.char_len(edge.text) then
        fallback[#fallback + 1] = segment
      end
    end
    table.sort(fallback, function(left, right)
      return left.index > right.index
    end)
    chosen = fallback[1]
  end
  if not chosen then
    table.sort(segments, function(left, right)
      return left.width > right.width
    end)
    chosen = segments[1]
  end
  if not chosen then
    return
  end

  local min_x = math.min(chosen.line[1].x, chosen.line[2].x)
  local max_x = math.max(chosen.line[1].x, chosen.line[2].x)
  local middle_x = min_x + math.floor((max_x - min_x) / 2)
  graph.column_width[middle_x] = math.max(graph.column_width[middle_x] or 0, text.char_len(edge.text) + 2)
  edge.label_line = chosen.line
end

local function analyze_edge_bundles(graph)
  if graph.config.graph_direction ~= "TD" then
    return {}
  end

  local bundles = {}
  local bundled_edges = {}

  local function can_bundle(edges)
    if #edges < 2 then
      return false
    end

    local first_style = edges[1].style
    local first_from = get_node_subgraph(graph, edges[1].from)
    local first_to = get_node_subgraph(graph, edges[1].to)

    for _, edge in ipairs(edges) do
      if edge.style ~= first_style or edge.text ~= "" or edge.from == edge.to then
        return false
      end
      local from_subgraph = get_node_subgraph(graph, edge.from)
      local to_subgraph = get_node_subgraph(graph, edge.to)
      if from_subgraph ~= first_from or to_subgraph ~= first_to or from_subgraph ~= to_subgraph then
        return false
      end
    end

    return true
  end

  local edges_by_target = {}
  for _, edge in ipairs(graph.edges) do
    if edge.from ~= edge.to then
      edges_by_target[edge.to] = edges_by_target[edge.to] or {}
      edges_by_target[edge.to][#edges_by_target[edge.to] + 1] = edge
    end
  end

  for target, edges in pairs(edges_by_target) do
    if can_bundle(edges) then
      local already_bundled = false
      for _, edge in ipairs(edges) do
        if bundled_edges[edge] then
          already_bundled = true
          break
        end
      end
      if not already_bundled then
        local others = {}
        for _, edge in ipairs(edges) do
          others[#others + 1] = edge.from
          bundled_edges[edge] = true
        end
        local bundle = {
          type = "fan-in",
          edges = edges,
          shared_node = target,
          other_nodes = others,
          junction_point = nil,
          shared_path = {},
          junction_dir = Middle,
          shared_node_dir = Middle,
        }
        for _, edge in ipairs(edges) do
          edge.bundle = bundle
        end
        bundles[#bundles + 1] = bundle
      end
    end
  end

  local edges_by_source = {}
  for _, edge in ipairs(graph.edges) do
    if edge.from ~= edge.to and not bundled_edges[edge] then
      edges_by_source[edge.from] = edges_by_source[edge.from] or {}
      edges_by_source[edge.from][#edges_by_source[edge.from] + 1] = edge
    end
  end

  for source, edges in pairs(edges_by_source) do
    if can_bundle(edges) then
      local others = {}
      for _, edge in ipairs(edges) do
        others[#others + 1] = edge.to
        bundled_edges[edge] = true
      end
      local bundle = {
        type = "fan-out",
        edges = edges,
        shared_node = source,
        other_nodes = others,
        junction_point = nil,
        shared_path = {},
        junction_dir = Middle,
        shared_node_dir = Middle,
      }
      for _, edge in ipairs(edges) do
        edge.bundle = bundle
      end
      bundles[#bundles + 1] = bundle
    end
  end

  return bundles
end

local function calculate_junction_point(bundle)
  local shared_coord = bundle.shared_node.grid_coord
  if bundle.type == "fan-in" then
    return { x = shared_coord.x + 1, y = shared_coord.y - 1 }
  end
  return { x = shared_coord.x + 1, y = shared_coord.y + 3 }
end

local function route_bundled_edges(graph, bundle)
  local direction = graph.config.graph_direction
  bundle.junction_point = calculate_junction_point(bundle)
  local junction = bundle.junction_point

  if bundle.type == "fan-in" then
    bundle.junction_dir = direction == "TD" and Up or Left
    bundle.shared_node_dir = direction == "TD" and Down or Right

    local target_coord = bundle.shared_node.grid_coord
    local target_entry = direction == "TD"
      and { x = target_coord.x + 1, y = target_coord.y }
      or { x = target_coord.x, y = target_coord.y + 1 }
    local shared_path = get_path(graph.grid, junction, target_entry)
    bundle.shared_path = shared_path and merge_path(shared_path) or { junction, target_entry }

    for _, edge in ipairs(bundle.edges) do
      local source_coord = edge.from.grid_coord
      local source_exit = direction == "TD"
        and { x = source_coord.x + 1, y = source_coord.y + 2 }
        or { x = source_coord.x + 2, y = source_coord.y + 1 }
      local path_to_junction = get_path(graph.grid, source_exit, junction)
      edge.path_to_junction = path_to_junction and merge_path(path_to_junction) or { source_exit, junction }
      edge.start_dir = direction == "TD" and Down or Right
      edge.end_dir = direction == "TD" and Up or Left
      edge.path = {}
      for _, coord in ipairs(edge.path_to_junction) do
        edge.path[#edge.path + 1] = coord
      end
      for index = 2, #bundle.shared_path do
        edge.path[#edge.path + 1] = bundle.shared_path[index]
      end
    end
  else
    bundle.junction_dir = direction == "TD" and Down or Right
    bundle.shared_node_dir = direction == "TD" and Up or Left

    local source_coord = bundle.shared_node.grid_coord
    local source_exit = direction == "TD"
      and { x = source_coord.x + 1, y = source_coord.y + 2 }
      or { x = source_coord.x + 2, y = source_coord.y + 1 }
    local shared_path = get_path(graph.grid, source_exit, junction)
    bundle.shared_path = shared_path and merge_path(shared_path) or { source_exit, junction }

    for _, edge in ipairs(bundle.edges) do
      local target_coord = edge.to.grid_coord
      local target_entry = direction == "TD"
        and { x = target_coord.x + 1, y = target_coord.y }
        or { x = target_coord.x, y = target_coord.y + 1 }
      local path_to_junction = get_path(graph.grid, junction, target_entry)
      edge.path_to_junction = path_to_junction and merge_path(path_to_junction) or { junction, target_entry }
      edge.start_dir = direction == "TD" and Down or Right
      edge.end_dir = direction == "TD" and Up or Left
      edge.path = {}
      for _, coord in ipairs(bundle.shared_path) do
        edge.path[#edge.path + 1] = coord
      end
      for index = 2, #edge.path_to_junction do
        edge.path[#edge.path + 1] = edge.path_to_junction[index]
      end
    end
  end
end

local function process_bundles(graph)
  for _, bundle in ipairs(graph.bundles) do
    route_bundled_edges(graph, bundle)
  end
end

local function grid_to_drawing_coord(graph, coord, direction)
  local target = direction and { x = coord.x + direction.x, y = coord.y + direction.y } or coord
  local x = 0
  for column = 0, target.x - 1 do
    x = x + (graph.column_width[column] or 0)
  end
  local y = 0
  for row = 0, target.y - 1 do
    y = y + (graph.row_height[row] or 0)
  end
  return {
    x = x + math.floor((graph.column_width[target.x] or 0) / 2) + graph.offset_x,
    y = y + math.floor((graph.row_height[target.y] or 0) / 2) + graph.offset_y,
  }
end

local function line_to_drawing(graph, line)
  local drawing_line = {}
  for _, coord in ipairs(line) do
    drawing_line[#drawing_line + 1] = grid_to_drawing_coord(graph, coord)
  end
  return drawing_line
end

local function calculate_subgraph_bounding_box(graph, subgraph)
  if #subgraph.nodes == 0 then
    return
  end

  local min_x = 1000000
  local min_y = 1000000
  local max_x = -1000000
  local max_y = -1000000

  for _, child in ipairs(subgraph.children) do
    calculate_subgraph_bounding_box(graph, child)
    if #child.nodes > 0 then
      min_x = math.min(min_x, child.min_x)
      min_y = math.min(min_y, child.min_y)
      max_x = math.max(max_x, child.max_x)
      max_y = math.max(max_y, child.max_y)
    end
  end

  for _, node in ipairs(subgraph.nodes) do
    if node.drawing_coord and node.drawing then
      local node_min_x = node.drawing_coord.x
      local node_min_y = node.drawing_coord.y
      local node_width, node_height = canvas.get_canvas_size(node.drawing)
      local node_max_x = node_min_x + node_width
      local node_max_y = node_min_y + node_height
      min_x = math.min(min_x, node_min_x)
      min_y = math.min(min_y, node_min_y)
      max_x = math.max(max_x, node_max_x)
      max_y = math.max(max_y, node_max_y)
    end
  end

  subgraph.min_x = min_x - 2
  subgraph.min_y = min_y - 4
  subgraph.max_x = max_x + 2
  subgraph.max_y = max_y + 2
end

local function ensure_subgraph_spacing(graph)
  local root_subgraphs = {}
  for _, subgraph in ipairs(graph.subgraphs) do
    if subgraph.parent == nil and #subgraph.nodes > 0 then
      root_subgraphs[#root_subgraphs + 1] = subgraph
    end
  end

  for left_index = 1, #root_subgraphs do
    for right_index = left_index + 1, #root_subgraphs do
      local left = root_subgraphs[left_index]
      local right = root_subgraphs[right_index]

      if left.min_x < right.max_x and left.max_x > right.min_x then
        if left.max_y >= right.min_y - 1 and left.min_y < right.min_y then
          right.min_y = left.max_y + 2
        elseif right.max_y >= left.min_y - 1 and right.min_y < left.min_y then
          left.min_y = right.max_y + 2
        end
      end

      if left.min_y < right.max_y and left.max_y > right.min_y then
        if left.max_x >= right.min_x - 1 and left.min_x < right.min_x then
          right.min_x = left.max_x + 2
        elseif right.max_x >= left.min_x - 1 and right.min_x < left.min_x then
          left.min_x = right.max_x + 2
        end
      end
    end
  end
end

local function calculate_subgraph_bounding_boxes(graph)
  for _, subgraph in ipairs(graph.subgraphs) do
    calculate_subgraph_bounding_box(graph, subgraph)
  end
  ensure_subgraph_spacing(graph)
end

local function offset_drawing_for_subgraphs(graph)
  if #graph.subgraphs == 0 then
    return
  end

  local min_x = 0
  local min_y = 0
  for _, subgraph in ipairs(graph.subgraphs) do
    min_x = math.min(min_x, subgraph.min_x)
    min_y = math.min(min_y, subgraph.min_y)
  end

  local offset_x = -min_x
  local offset_y = -min_y
  if offset_x == 0 and offset_y == 0 then
    return
  end

  graph.offset_x = offset_x
  graph.offset_y = offset_y

  for _, subgraph in ipairs(graph.subgraphs) do
    subgraph.min_x = subgraph.min_x + offset_x
    subgraph.max_x = subgraph.max_x + offset_x
    subgraph.min_y = subgraph.min_y + offset_y
    subgraph.max_y = subgraph.max_y + offset_y
  end

  for _, node in ipairs(graph.nodes) do
    if node.drawing_coord then
      node.drawing_coord.x = node.drawing_coord.x + offset_x
      node.drawing_coord.y = node.drawing_coord.y + offset_y
    end
  end
end

local function create_mapping(graph)
  local highest_position_per_level = {}
  for index = 0, 100 do
    highest_position_per_level[index] = 0
  end

  local nodes_found = {}
  local initial_roots = {}
  for _, node in ipairs(graph.nodes) do
    if not nodes_found[node.name] then
      initial_roots[#initial_roots + 1] = node
    end
    nodes_found[node.name] = true
    for _, child in ipairs(get_children(graph, node)) do
      nodes_found[child.name] = true
    end
  end

  local root_nodes = {}
  for _, node in ipairs(initial_roots) do
    local node_subgraph = get_node_subgraph(graph, node)
    if not node_subgraph then
      root_nodes[#root_nodes + 1] = node
    else
      local external_incoming = false
      for _, edge in ipairs(graph.edges) do
        if edge.to == node and get_node_subgraph(graph, edge.from) ~= node_subgraph then
          external_incoming = true
          break
        end
      end
      if not external_incoming then
        root_nodes[#root_nodes + 1] = node
      end
    end
  end

  local has_external_roots = false
  local has_subgraph_roots_with_edges = false
  for _, node in ipairs(root_nodes) do
    if node_in_subgraph(graph, node) then
      if #get_children(graph, node) > 0 then
        has_subgraph_roots_with_edges = true
      end
    else
      has_external_roots = true
    end
  end
  local should_separate = graph.config.graph_direction == "LR" and has_external_roots and has_subgraph_roots_with_edges

  local external_roots = {}
  local subgraph_roots = {}
  if should_separate then
    for _, node in ipairs(root_nodes) do
      if node_in_subgraph(graph, node) then
        subgraph_roots[#subgraph_roots + 1] = node
      else
        external_roots[#external_roots + 1] = node
      end
    end
  else
    external_roots = root_nodes
  end

  for _, node in ipairs(external_roots) do
    local requested = graph.config.graph_direction == "LR"
      and { x = 0, y = highest_position_per_level[0] }
      or { x = highest_position_per_level[0], y = 0 }
    reserve_spot_in_grid(graph, node, requested)
    highest_position_per_level[0] = highest_position_per_level[0] + 4
  end

  if should_separate and #subgraph_roots > 0 then
    for _, node in ipairs(subgraph_roots) do
      local requested = graph.config.graph_direction == "LR"
        and { x = 4, y = highest_position_per_level[4] }
        or { x = highest_position_per_level[4], y = 4 }
      reserve_spot_in_grid(graph, node, requested)
      highest_position_per_level[4] = highest_position_per_level[4] + 4
    end
  end

  local placed_count = #external_roots + #subgraph_roots
  while placed_count < #graph.nodes do
    local previous_count = placed_count
    for _, node in ipairs(graph.nodes) do
      if node.grid_coord then
        local grid_coord = node.grid_coord
        for _, child in ipairs(get_children(graph, node)) do
          if not child.grid_coord then
            local parent_subgraph = get_node_subgraph(graph, node)
            local child_subgraph = get_node_subgraph(graph, child)
            local edge_direction = parent_subgraph and parent_subgraph == child_subgraph and parent_subgraph.direction or graph.config.graph_direction
            local child_level = edge_direction == "LR" and (grid_coord.x + 4) or (grid_coord.y + 4)
            local highest_position
            if edge_direction ~= graph.config.graph_direction then
              highest_position = edge_direction == "LR" and grid_coord.y or grid_coord.x
            else
              highest_position = highest_position_per_level[child_level] or 0
            end

            local requested = edge_direction == "LR"
              and { x = child_level, y = highest_position }
              or { x = highest_position, y = child_level }
            reserve_spot_in_grid(graph, child, requested, edge_direction)
            if edge_direction == graph.config.graph_direction then
              highest_position_per_level[child_level] = highest_position + 4
            end
            placed_count = placed_count + 1
          end
        end
      end
    end
    if placed_count == previous_count then
      break
    end
  end

  for _, node in ipairs(graph.nodes) do
    set_column_width(graph, node)
  end

  graph.bundles = analyze_edge_bundles(graph)
  process_bundles(graph)

  for _, edge in ipairs(graph.edges) do
    if edge.bundle and #edge.path > 0 then
      increase_grid_size_for_path(graph, edge.path)
      determine_label_line(graph, edge)
    else
      determine_path(graph, edge)
      increase_grid_size_for_path(graph, edge.path)
      determine_label_line(graph, edge)
    end
  end

  for _, node in ipairs(graph.nodes) do
    node.drawing_coord = grid_to_drawing_coord(graph, node.grid_coord)
    node.drawing = draw_node(node, graph)
  end

  canvas.set_canvas_size_to_grid(graph.canvas, graph.column_width, graph.row_height)
  calculate_subgraph_bounding_boxes(graph)
  offset_drawing_for_subgraphs(graph)
end

local function draw_line(target_canvas, from, to, offset_from, offset_to, style)
  local direction = determine_direction(from, to)
  local chars = LINE_CHARS[style or "solid"]
  local drawn = {}

  local function add(x, y, char)
    drawn[#drawn + 1] = { x = x, y = y }
    target_canvas[x][y] = char
  end

  if direction_eq(direction, Up) then
    for y = from.y - offset_from, to.y - offset_to, -1 do
      add(from.x, y, chars.v)
    end
  elseif direction_eq(direction, Down) then
    for y = from.y + offset_from, to.y + offset_to do
      add(from.x, y, chars.v)
    end
  elseif direction_eq(direction, Left) then
    for x = from.x - offset_from, to.x - offset_to, -1 do
      add(x, from.y, chars.h)
    end
  elseif direction_eq(direction, Right) then
    for x = from.x + offset_from, to.x + offset_to do
      add(x, from.y, chars.h)
    end
  elseif direction_eq(direction, UpperLeft) then
    for x = from.x - offset_from, to.x, -1 do
      add(x, from.y, chars.h)
    end
    for y = from.y - 1, to.y - offset_to, -1 do
      add(to.x, y, chars.v)
    end
  elseif direction_eq(direction, UpperRight) then
    for x = from.x + offset_from, to.x do
      add(x, from.y, chars.h)
    end
    for y = from.y - 1, to.y - offset_to, -1 do
      add(to.x, y, chars.v)
    end
  elseif direction_eq(direction, LowerLeft) then
    for x = from.x - offset_from, to.x, -1 do
      add(x, from.y, chars.h)
    end
    for y = from.y + 1, to.y + offset_to do
      add(to.x, y, chars.v)
    end
  elseif direction_eq(direction, LowerRight) then
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

local function reverse_direction(direction)
  return get_opposite(direction)
end

local function draw_text_on_line(target_canvas, drawing_line, label, is_upward_edge)
  if #drawing_line < 2 then
    return
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

  local label_lines = text.split_label_lines(label)
  local start_y = middle_y - math.floor((#label_lines - 1) / 2)
  for index, line in ipairs(label_lines) do
    local start_x = middle_x - math.floor(text.char_len(line) / 2)
    canvas.draw_text(target_canvas, { x = start_x, y = start_y + index - 1 }, line, false)
  end
end

local function draw_arrow_label(graph, edge)
  local label_canvas = canvas.copy_canvas(graph.canvas)
  if edge.text == "" or #edge.label_line == 0 then
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

  draw_text_on_line(label_canvas, drawing_line, edge.text, is_upward_edge)
  return label_canvas
end

local function draw_box_start(graph, path, first_line, source_shape)
  local result = canvas.copy_canvas(graph.canvas)
  if source_shape == "state-start" or source_shape == "state-end" or #path < 2 then
    return result
  end

  local from = first_line[1]
  local direction = determine_direction(path[1], path[2])
  if direction_eq(direction, Up) then
    result[from.x][from.y + 1] = "┴"
  elseif direction_eq(direction, Down) then
    result[from.x][from.y - 1] = "┬"
  elseif direction_eq(direction, Left) then
    result[from.x + 1][from.y] = "┤"
  elseif direction_eq(direction, Right) then
    result[from.x - 1][from.y] = "├"
  end
  return result
end

local function draw_arrow_head(graph, last_line, fallback_direction)
  local arrow_canvas = canvas.copy_canvas(graph.canvas)
  if #last_line == 0 then
    return arrow_canvas
  end

  local from = last_line[1]
  local last_position = last_line[#last_line]
  local direction = determine_direction(from, last_position)
  if #last_line == 1 or direction_eq(direction, Middle) then
    direction = fallback_direction
  end

  local char = "●"
  if direction_eq(direction, Up) then
    char = "▲"
  elseif direction_eq(direction, Down) then
    char = "▼"
  elseif direction_eq(direction, Left) then
    char = "◄"
  elseif direction_eq(direction, Right) then
    char = "►"
  elseif direction_eq(direction, UpperRight) then
    char = "◥"
  elseif direction_eq(direction, UpperLeft) then
    char = "◤"
  elseif direction_eq(direction, LowerRight) then
    char = "◢"
  elseif direction_eq(direction, LowerLeft) then
    char = "◣"
  end

  arrow_canvas[last_position.x][last_position.y] = char
  return arrow_canvas
end

local function draw_corners(graph, path)
  local result = canvas.copy_canvas(graph.canvas)
  for index = 2, #path - 1 do
    local coord = path[index]
    local drawing_coord = grid_to_drawing_coord(graph, coord)
    local previous_direction = determine_direction(path[index - 1], coord)
    local next_direction = determine_direction(coord, path[index + 1])

    local corner = "+"
    if (direction_eq(previous_direction, Right) and direction_eq(next_direction, Down))
      or (direction_eq(previous_direction, Up) and direction_eq(next_direction, Left)) then
      corner = "┐"
    elseif (direction_eq(previous_direction, Right) and direction_eq(next_direction, Up))
      or (direction_eq(previous_direction, Down) and direction_eq(next_direction, Left)) then
      corner = "┘"
    elseif (direction_eq(previous_direction, Left) and direction_eq(next_direction, Down))
      or (direction_eq(previous_direction, Up) and direction_eq(next_direction, Right)) then
      corner = "┌"
    elseif (direction_eq(previous_direction, Left) and direction_eq(next_direction, Up))
      or (direction_eq(previous_direction, Down) and direction_eq(next_direction, Right)) then
      corner = "└"
    end

    result[drawing_coord.x][drawing_coord.y] = corner
  end
  return result
end

local function draw_path(graph, path, style)
  local target_canvas = canvas.copy_canvas(graph.canvas)
  local previous_coord = path[1]
  local lines_drawn = {}
  local directions = {}

  for index = 2, #path do
    local next_coord = path[index]
    local previous_drawing = grid_to_drawing_coord(graph, previous_coord)
    local next_drawing = grid_to_drawing_coord(graph, next_coord)

    if not drawing_coord_equals(previous_drawing, next_drawing) then
      local direction = determine_direction(previous_coord, next_coord)
      local segment = draw_line(target_canvas, previous_drawing, next_drawing, 1, -1, style)
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

local function draw_arrow(graph, edge)
  if #edge.path == 0 then
    local empty = canvas.copy_canvas(graph.canvas)
    return empty, empty, empty, empty, empty, empty
  end

  local label_canvas = draw_arrow_label(graph, edge)
  local path_canvas, lines_drawn, directions = draw_path(graph, edge.path, edge.style)
  local box_start_canvas = draw_box_start(graph, edge.path, lines_drawn[1] or {}, edge.from.shape)
  local arrow_end_canvas = edge.has_arrow_end
      and draw_arrow_head(graph, lines_drawn[#lines_drawn] or {}, directions[#directions] or edge.end_dir)
      or canvas.copy_canvas(graph.canvas)

  local arrow_start_canvas = canvas.copy_canvas(graph.canvas)
  if edge.has_arrow_start and #lines_drawn > 0 then
    local first_line = lines_drawn[1]
    local first_point = first_line[1]
    local start_direction = reverse_direction(directions[1])
    local arrow_position = { x = first_point.x, y = first_point.y }
    if direction_eq(directions[1], Right) then
      arrow_position.x = first_point.x - 1
    elseif direction_eq(directions[1], Left) then
      arrow_position.x = first_point.x + 1
    elseif direction_eq(directions[1], Down) then
      arrow_position.y = first_point.y - 1
    elseif direction_eq(directions[1], Up) then
      arrow_position.y = first_point.y + 1
    end
    arrow_start_canvas = draw_arrow_head(graph, { first_point, arrow_position }, start_direction)
  end

  local corners_canvas = draw_corners(graph, edge.path)
  return path_canvas, box_start_canvas, arrow_end_canvas, arrow_start_canvas, corners_canvas, label_canvas
end

local function get_node_attachment_point(graph, node, direction)
  local grid_coord = node.grid_coord
  local width = (graph.column_width[grid_coord.x] or 0) + (graph.column_width[grid_coord.x + 1] or 0) + 1
  local height = (graph.row_height[grid_coord.y] or 0) + (graph.row_height[grid_coord.y + 1] or 0) + 1
  return get_shape_attachment_point(node.shape, direction, { width = width, height = height }, node.drawing_coord)
end

local function draw_bundled_edge_segment(graph, edge, bundle)
  local empty = canvas.copy_canvas(graph.canvas)
  if not edge.path_to_junction or #edge.path_to_junction == 0 then
    return empty, empty, empty, empty, empty, empty
  end

  local path_canvas = canvas.copy_canvas(graph.canvas)
  local drawing_path = {}
  for index, grid_coord in ipairs(edge.path_to_junction) do
    if bundle.type == "fan-in" and index == 1 then
      drawing_path[index] = get_node_attachment_point(graph, edge.from, edge.start_dir)
    elseif bundle.type == "fan-out" and index == #edge.path_to_junction then
      drawing_path[index] = get_node_attachment_point(graph, edge.to, edge.end_dir)
    else
      drawing_path[index] = grid_to_drawing_coord(graph, grid_coord)
    end
  end

  for index = 2, #drawing_path do
    if not drawing_coord_equals(drawing_path[index - 1], drawing_path[index]) then
      draw_line(path_canvas, drawing_path[index - 1], drawing_path[index], 1, -1, edge.style)
    end
  end

  local corners_canvas = canvas.copy_canvas(graph.canvas)
  for index = 2, #edge.path_to_junction - 1 do
    local coord = edge.path_to_junction[index]
    local drawing_coord = grid_to_drawing_coord(graph, coord)
    local previous_direction = determine_direction(edge.path_to_junction[index - 1], coord)
    local next_direction = determine_direction(coord, edge.path_to_junction[index + 1])

    local corner = "+"
    if (direction_eq(previous_direction, Right) and direction_eq(next_direction, Down))
      or (direction_eq(previous_direction, Up) and direction_eq(next_direction, Left)) then
      corner = "┐"
    elseif (direction_eq(previous_direction, Right) and direction_eq(next_direction, Up))
      or (direction_eq(previous_direction, Down) and direction_eq(next_direction, Left)) then
      corner = "┘"
    elseif (direction_eq(previous_direction, Left) and direction_eq(next_direction, Down))
      or (direction_eq(previous_direction, Up) and direction_eq(next_direction, Right)) then
      corner = "┌"
    elseif (direction_eq(previous_direction, Left) and direction_eq(next_direction, Up))
      or (direction_eq(previous_direction, Down) and direction_eq(next_direction, Right)) then
      corner = "└"
    end

    corners_canvas[drawing_coord.x][drawing_coord.y] = corner
  end

  local box_start_canvas = canvas.copy_canvas(graph.canvas)
  if bundle.type == "fan-in" and #edge.path_to_junction >= 2 then
    local first_point = drawing_path[1]
    local direction = determine_direction(edge.path_to_junction[1], edge.path_to_junction[2])
    if direction_eq(direction, Up) then
      box_start_canvas[first_point.x][first_point.y] = "┴"
    elseif direction_eq(direction, Down) then
      box_start_canvas[first_point.x][first_point.y] = "┬"
    elseif direction_eq(direction, Left) then
      box_start_canvas[first_point.x][first_point.y] = "┤"
    elseif direction_eq(direction, Right) then
      box_start_canvas[first_point.x][first_point.y] = "├"
    end
  end

  return path_canvas, box_start_canvas, empty, empty, corners_canvas, empty
end

local function draw_bundle_shared_path(graph, bundle)
  local path_canvas = canvas.copy_canvas(graph.canvas)
  local corners_canvas = canvas.copy_canvas(graph.canvas)
  if #bundle.shared_path < 2 then
    return path_canvas, corners_canvas
  end

  local drawing_path = {}
  for index, grid_coord in ipairs(bundle.shared_path) do
    if bundle.type == "fan-in" and index == #bundle.shared_path then
      drawing_path[index] = get_node_attachment_point(graph, bundle.shared_node, Up)
    elseif bundle.type == "fan-out" and index == 1 then
      drawing_path[index] = get_node_attachment_point(graph, bundle.shared_node, Down)
    else
      drawing_path[index] = grid_to_drawing_coord(graph, grid_coord)
    end
  end

  for index = 2, #drawing_path do
    if not drawing_coord_equals(drawing_path[index - 1], drawing_path[index]) then
      draw_line(path_canvas, drawing_path[index - 1], drawing_path[index], 1, -1, bundle.edges[1].style)
    end
  end

  for index = 2, #bundle.shared_path - 1 do
    local coord = bundle.shared_path[index]
    local drawing_coord = grid_to_drawing_coord(graph, coord)
    local previous_direction = determine_direction(bundle.shared_path[index - 1], coord)
    local next_direction = determine_direction(coord, bundle.shared_path[index + 1])
    local corner = "+"
    if (direction_eq(previous_direction, Right) and direction_eq(next_direction, Down))
      or (direction_eq(previous_direction, Up) and direction_eq(next_direction, Left)) then
      corner = "┐"
    elseif (direction_eq(previous_direction, Right) and direction_eq(next_direction, Up))
      or (direction_eq(previous_direction, Down) and direction_eq(next_direction, Left)) then
      corner = "┘"
    elseif (direction_eq(previous_direction, Left) and direction_eq(next_direction, Down))
      or (direction_eq(previous_direction, Up) and direction_eq(next_direction, Right)) then
      corner = "┌"
    elseif (direction_eq(previous_direction, Left) and direction_eq(next_direction, Up))
      or (direction_eq(previous_direction, Down) and direction_eq(next_direction, Right)) then
      corner = "└"
    end
    corners_canvas[drawing_coord.x][drawing_coord.y] = corner
  end

  return path_canvas, corners_canvas
end

local function draw_bundle_arrowhead(graph, bundle)
  local arrow_canvas = canvas.copy_canvas(graph.canvas)
  if #bundle.shared_path < 2 then
    return arrow_canvas
  end

  local last_direction = determine_direction(bundle.shared_path[#bundle.shared_path - 1], bundle.shared_path[#bundle.shared_path])
  local position = get_node_attachment_point(graph, bundle.shared_node, Up)
  position.y = position.y - 1

  local char = direction_eq(last_direction, Up) and "▲"
    or direction_eq(last_direction, Down) and "▼"
    or direction_eq(last_direction, Left) and "◄"
    or "►"

  arrow_canvas[position.x][position.y] = char
  return arrow_canvas
end

local function draw_bundled_edge_arrowhead(graph, edge)
  local arrow_canvas = canvas.copy_canvas(graph.canvas)
  if not edge.path_to_junction or #edge.path_to_junction < 2 then
    return arrow_canvas
  end

  local last_direction = determine_direction(edge.path_to_junction[#edge.path_to_junction - 1], edge.path_to_junction[#edge.path_to_junction])
  local position = get_node_attachment_point(graph, edge.to, Up)
  position.y = position.y - 1

  local char = direction_eq(last_direction, Up) and "▲"
    or direction_eq(last_direction, Down) and "▼"
    or direction_eq(last_direction, Left) and "◄"
    or "►"

  arrow_canvas[position.x][position.y] = char
  return arrow_canvas
end

local function draw_junction_character(graph, bundle)
  local junction_canvas = canvas.copy_canvas(graph.canvas)
  if not bundle.junction_point then
    return junction_canvas
  end

  local drawing_coord = grid_to_drawing_coord(graph, bundle.junction_point)
  local has_up, has_down, has_left, has_right = false, false, false, false

  if #bundle.shared_path >= 2 then
    local junction_index = bundle.type == "fan-in" and 1 or #bundle.shared_path
    local adjacent_index = bundle.type == "fan-in" and 2 or (#bundle.shared_path - 1)
    local shared_direction = determine_direction(bundle.shared_path[junction_index], bundle.shared_path[adjacent_index])
    if direction_eq(shared_direction, Down) then
      has_down = true
    elseif direction_eq(shared_direction, Up) then
      has_up = true
    elseif direction_eq(shared_direction, Right) then
      has_right = true
    elseif direction_eq(shared_direction, Left) then
      has_left = true
    end
  end

  for _, edge in ipairs(bundle.edges) do
    if edge.path_to_junction and #edge.path_to_junction >= 2 then
      local junction_index = bundle.type == "fan-in" and #edge.path_to_junction or 1
      local adjacent_index = bundle.type == "fan-in" and (#edge.path_to_junction - 1) or 2
      local arrival_direction = determine_direction(edge.path_to_junction[adjacent_index], edge.path_to_junction[junction_index])
      if direction_eq(arrival_direction, Down) then
        has_up = true
      elseif direction_eq(arrival_direction, Up) then
        has_down = true
      elseif direction_eq(arrival_direction, Right) then
        has_left = true
      elseif direction_eq(arrival_direction, Left) then
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

local function draw_subgraph_box(subgraph)
  local width = subgraph.max_x - subgraph.min_x
  local height = subgraph.max_y - subgraph.min_y
  if width <= 0 or height <= 0 then
    return canvas.mk_canvas(0, 0)
  end

  local subgraph_canvas = canvas.mk_canvas(width, height)
  for x = 1, width - 1 do
    subgraph_canvas[x][0] = "─"
    subgraph_canvas[x][height] = "─"
  end
  for y = 1, height - 1 do
    subgraph_canvas[0][y] = "│"
    subgraph_canvas[width][y] = "│"
  end
  subgraph_canvas[0][0] = "┌"
  subgraph_canvas[width][0] = "┐"
  subgraph_canvas[0][height] = "└"
  subgraph_canvas[width][height] = "┘"
  return subgraph_canvas
end

local function draw_subgraph_label(subgraph)
  local width = subgraph.max_x - subgraph.min_x
  local height = subgraph.max_y - subgraph.min_y
  if width <= 0 or height <= 0 then
    return canvas.mk_canvas(0, 0), { x = 0, y = 0 }
  end

  local label_canvas = canvas.mk_canvas(width, height)
  for index, line in ipairs(text.split_label_lines(subgraph.name)) do
    local line_width = text.char_len(line)
    local label_x = math.floor(width / 2) - math.floor(line_width / 2)
    if label_x < 1 then
      label_x = 1
    end
    canvas.draw_text(label_canvas, { x = label_x, y = index }, line, true)
  end

  return label_canvas, { x = subgraph.min_x, y = subgraph.min_y }
end

local function sort_subgraphs_by_depth(subgraphs)
  local sorted = {}
  for _, subgraph in ipairs(subgraphs) do
    sorted[#sorted + 1] = subgraph
  end

  local function depth(subgraph)
    local level = 0
    local current = subgraph.parent
    while current do
      level = level + 1
      current = current.parent
    end
    return level
  end

  table.sort(sorted, function(left, right)
    return depth(left) < depth(right)
  end)

  return sorted
end

local function draw_graph(graph)
  for _, subgraph in ipairs(sort_subgraphs_by_depth(graph.subgraphs)) do
    local subgraph_canvas = draw_subgraph_box(subgraph)
    graph.canvas = canvas.merge_canvases(graph.canvas, { x = subgraph.min_x, y = subgraph.min_y }, { subgraph_canvas })
  end

  for _, node in ipairs(graph.nodes) do
    if not node.drawn and node.drawing_coord and node.drawing then
      graph.canvas = canvas.merge_canvases(graph.canvas, node.drawing_coord, { node.drawing })
      node.drawn = true
    end
  end

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
      local path_canvas, box_start_canvas, _, _, corners_canvas, label_canvas = draw_bundled_edge_segment(graph, edge, edge.bundle)
      line_canvases[#line_canvases + 1] = path_canvas
      corner_canvases[#corner_canvases + 1] = corners_canvas
      box_start_canvases[#box_start_canvases + 1] = box_start_canvas
      label_canvases[#label_canvases + 1] = label_canvas

      if not processed_bundles[edge.bundle] then
        processed_bundles[edge.bundle] = true
        local shared_path_canvas, shared_corners_canvas = draw_bundle_shared_path(graph, edge.bundle)
        line_canvases[#line_canvases + 1] = shared_path_canvas
        corner_canvases[#corner_canvases + 1] = shared_corners_canvas
        if edge.bundle.type == "fan-in" then
          arrow_end_canvases[#arrow_end_canvases + 1] = draw_bundle_arrowhead(graph, edge.bundle)
        end
        junction_canvases[#junction_canvases + 1] = draw_junction_character(graph, edge.bundle)
      end

      if edge.bundle.type == "fan-out" and edge.has_arrow_end then
        arrow_end_canvases[#arrow_end_canvases + 1] = draw_bundled_edge_arrowhead(graph, edge)
      end
    else
      local path_canvas, box_start_canvas, arrow_end_canvas, arrow_start_canvas, corners_canvas, label_canvas = draw_arrow(graph, edge)
      line_canvases[#line_canvases + 1] = path_canvas
      corner_canvases[#corner_canvases + 1] = corners_canvas
      arrow_end_canvases[#arrow_end_canvases + 1] = arrow_end_canvas
      arrow_start_canvases[#arrow_start_canvases + 1] = arrow_start_canvas
      box_start_canvases[#box_start_canvases + 1] = box_start_canvas
      label_canvases[#label_canvases + 1] = label_canvas
    end
  end

  if #line_canvases > 0 then
    graph.canvas = canvas.merge_canvases(graph.canvas, { x = 0, y = 0 }, line_canvases)
  end
  if #corner_canvases > 0 then
    graph.canvas = canvas.merge_canvases(graph.canvas, { x = 0, y = 0 }, corner_canvases)
  end
  if #junction_canvases > 0 then
    graph.canvas = canvas.merge_canvases(graph.canvas, { x = 0, y = 0 }, junction_canvases)
  end
  if #arrow_end_canvases > 0 then
    graph.canvas = canvas.merge_canvases(graph.canvas, { x = 0, y = 0 }, arrow_end_canvases)
  end
  if #box_start_canvases > 0 then
    graph.canvas = canvas.merge_canvases(graph.canvas, { x = 0, y = 0 }, box_start_canvases)
  end
  if #arrow_start_canvases > 0 then
    graph.canvas = canvas.merge_canvases(graph.canvas, { x = 0, y = 0 }, arrow_start_canvases)
  end
  if #label_canvases > 0 then
    graph.canvas = canvas.merge_canvases(graph.canvas, { x = 0, y = 0 }, label_canvases)
  end

  for _, subgraph in ipairs(graph.subgraphs) do
    if #subgraph.nodes > 0 then
      local label_canvas, offset = draw_subgraph_label(subgraph)
      graph.canvas = canvas.merge_canvases(graph.canvas, offset, { label_canvas })
    end
  end
end

local function render_graph(parsed)
  local graph = convert_graph(parsed)
  if #graph.nodes == 0 then
    return {}
  end

  create_mapping(graph)
  draw_graph(graph)
  if graph.parsed_direction == "BT" then
    canvas.flip_canvas_vertically(graph.canvas)
  end
  return canvas.canvas_to_lines(graph.canvas)
end

local M = {}
M.render_graph = render_graph
return M
