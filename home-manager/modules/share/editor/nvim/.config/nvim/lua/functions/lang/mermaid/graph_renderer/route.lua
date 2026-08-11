local text = require("functions.lang.mermaid.text")
local geometry = require("functions.lang.mermaid.graph_renderer.geometry")

local Directions = geometry.Directions

---Stage 2b: once nodes have grid slots, route the edges through the free cells.
---
---This module keeps the old routing heuristics intact where possible, but it now owns
---them in one place instead of smearing pathfinding, bundling, and label selection
---across the renderer entrypoint.

---Look up the innermost subgraph that contains a given node.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph that owns the node-to-subgraph index.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the node whose containing subgraph should be found.
---@return dotfiles.mermaid.graph_renderer.LayoutSubgraph|nil subgraph the innermost containing subgraph, or nil when the node is top-level.
local function get_node_subgraph(graph, node)
  return graph.innermost_subgraph_by_node[node]
end

---Resolve the layout direction that should govern routing around a node.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph that provides the default graph direction.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the node whose effective routing direction should be determined.
---@return dotfiles.mermaid.graph_renderer.GraphDirection direction the inherited or graph-level routing direction for the node.
local function get_effective_direction(graph, node)
  local subgraph = get_node_subgraph(graph, node)
  while subgraph do
    if subgraph.direction then
      return subgraph.direction
    end
    subgraph = subgraph.parent
  end
  return graph.config.graph_direction
end

---Collect every outgoing edge that starts at the given node.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose edges should be scanned.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the source node whose outgoing edges should be returned.
---@return dotfiles.mermaid.graph_renderer.LayoutEdge[] edges the outgoing edges whose `from` node matches the given node.
local function get_edges_from_node(graph, node)
  local edges = {}
  for _, edge in ipairs(graph.edges) do
    if edge.from == node then
      edges[#edges + 1] = edge
    end
  end
  return edges
end

---Collect the direct child nodes reached by the given node's outgoing edges.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose edges define child relationships.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the source node whose edge targets should be returned.
---@return dotfiles.mermaid.graph_renderer.LayoutNode[] children the destination nodes reached directly from the given node.
local function get_children(graph, node)
  local children = {}
  for _, edge in ipairs(get_edges_from_node(graph, node)) do
    children[#children + 1] = edge.to
  end
  return children
end

---Check whether a node belongs to any subgraph.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph that owns the node-to-subgraph index.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the node to test for subgraph membership.
---@return boolean in_subgraph true when the node belongs to an innermost subgraph, false otherwise.
local function node_in_subgraph(graph, node)
  return get_node_subgraph(graph, node) ~= nil
end

---Check whether a node is the highest external-entry target inside its subgraph.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose edges and subgraphs should be inspected.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the node to test for incoming edges from outside its subgraph.
---@return boolean has_external_entry true when the node needs extra top padding for an external incoming edge.
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

---Check whether a node has a backwards edge that leaves its subgraph.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose edges and coordinates should be inspected.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the node to test for backward external edges.
---@return boolean has_back_edge true when the node needs extra routing space for a backward external edge.
local function has_back_edge_to_outside_subgraph(graph, node)
  local node_subgraph = get_node_subgraph(graph, node)
  if not node_subgraph or not node.grid_coord then
    return false
  end

  for _, edge in ipairs(graph.edges) do
    if edge.from == node and edge.to.grid_coord and get_node_subgraph(graph, edge.to) ~= node_subgraph then
      if graph.config.graph_direction == "LR" and edge.to.grid_coord.x <= node.grid_coord.x then
        return true
      end
      if graph.config.graph_direction == "TD" and edge.to.grid_coord.y <= node.grid_coord.y then
        return true
      end
    end
  end

  return false
end

---Reserve grid column and row space for a node and the padding its edges may require.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose row and column budgets should be updated.
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the placed node whose footprint and padding should be reserved.
local function set_column_width(graph, node)
  local dimensions = assert(node.dimensions, "layout nodes must be measured before routing")
  local grid_coord = assert(node.grid_coord, "layout nodes must be placed before routing")

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

  if has_back_edge_to_outside_subgraph(graph, node) then
    local path_row = grid_coord.y + 3
    graph.row_height[path_row] = math.max(graph.row_height[path_row] or 0, graph.config.padding_y + 4)
  end
end

---Ensure every grid cell touched by a path has at least minimal row and column sizing.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose row and column budgets should be expanded.
---@param path dotfiles.mermaid.graph_renderer.GridPath the path whose occupied grid cells need width and height entries.
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

---@class dotfiles.mermaid.graph_renderer.MinHeap
---@field items dotfiles.mermaid.graph_renderer.HeapItem[]
local MinHeap = {}
MinHeap.__index = MinHeap

---Create an empty min-heap for A* frontier items.
---@return dotfiles.mermaid.graph_renderer.MinHeap heap a new heap instance with no queued items.
function MinHeap.new()
  return setmetatable({ items = {} }, MinHeap)
end

---Insert an item into the min-heap while preserving heap order by priority.
---@param self dotfiles.mermaid.graph_renderer.MinHeap the heap instance receiving the new item.
---@param item dotfiles.mermaid.graph_renderer.HeapItem the frontier item to enqueue.
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

---Remove and return the lowest-priority item from the min-heap.
---@param self dotfiles.mermaid.graph_renderer.MinHeap the heap instance to pop from.
---@return dotfiles.mermaid.graph_renderer.HeapItem|nil item the lowest-priority queued item, or nil when the heap is empty.
function MinHeap:pop()
  local items = self.items
  if #items == 0 then
    return nil
  end

  local top = items[1]
  local last = table.remove(items)
  if #items > 0 and last then
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

---Report how many items are currently stored in the min-heap.
---@param self dotfiles.mermaid.graph_renderer.MinHeap the heap instance whose size should be measured.
---@return integer count the number of queued items in the heap.
function MinHeap:length()
  return #self.items
end

---@type dotfiles.mermaid.graph_renderer.GridCoord[]
local MOVE_STEPS = {
  { x = 1, y = 0 },
  { x = -1, y = 0 },
  { x = 0, y = 1 },
  { x = 0, y = -1 },
}

---Estimate the remaining routing cost between two grid coordinates.
---@param left dotfiles.mermaid.graph_renderer.GridCoord the current grid coordinate in the path search.
---@param right dotfiles.mermaid.graph_renderer.GridCoord the destination grid coordinate in the path search.
---@return integer estimated_cost the heuristic distance used to prioritize A* exploration.
local function heuristic(left, right)
  local abs_x = math.abs(left.x - right.x)
  local abs_y = math.abs(left.y - right.y)
  if abs_x == 0 or abs_y == 0 then
    return abs_x + abs_y
  end
  return abs_x + abs_y + 1
end

---Check whether a grid coordinate is available for routing.
---@param grid table<string, dotfiles.mermaid.graph_renderer.LayoutNode> the occupancy map of placed layout nodes.
---@param coord dotfiles.mermaid.graph_renderer.GridCoord the grid coordinate to test for availability.
---@return boolean is_free true when the coordinate is in bounds and unoccupied by a node.
local function is_free_in_grid(grid, coord)
  if coord.x < 0 or coord.y < 0 then
    return false
  end
  return grid[geometry.grid_key(coord)] == nil
end

---Find a walkable grid path between two coordinates with A* search.
---@param grid table<string, dotfiles.mermaid.graph_renderer.LayoutNode> the occupancy map of placed layout nodes.
---@param from dotfiles.mermaid.graph_renderer.GridCoord the grid coordinate where the search should begin.
---@param to dotfiles.mermaid.graph_renderer.GridCoord the grid coordinate the search should reach.
---@return dotfiles.mermaid.graph_renderer.GridPath|nil path the discovered path from start to end, or nil when no route exists.
local function get_path(grid, from, to)
  local priority_queue = MinHeap.new()
  priority_queue:push({ coord = from, priority = 0 })

  local cost_so_far = { [geometry.grid_key(from)] = 0 }
  local came_from = { [geometry.grid_key(from)] = false }

  while priority_queue:length() > 0 do
    local next_item = priority_queue:pop()
    if not next_item then
      break
    end

    local current = next_item.coord
    if geometry.same_grid_coord(current, to) then
      local path = {}
      local cursor = current
      while cursor do
        table.insert(path, 1, cursor)
        local previous = came_from[geometry.grid_key(cursor)]
        cursor = previous or nil
      end
      return path
    end

    local current_cost = cost_so_far[geometry.grid_key(current)]
    for _, movement in ipairs(MOVE_STEPS) do
      local next_coord = { x = current.x + movement.x, y = current.y + movement.y }
      if (not is_free_in_grid(grid, next_coord)) and not geometry.same_grid_coord(next_coord, to) then
        goto continue
      end

      local new_cost = current_cost + 1
      local next_key = geometry.grid_key(next_coord)
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

---Remove redundant intermediate points from a path that continues in the same direction.
---@param path dotfiles.mermaid.graph_renderer.GridPath the path to compact by merging collinear steps.
---@return dotfiles.mermaid.graph_renderer.GridPath merged the simplified path with unnecessary interior points removed.
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

---Choose attachment directions for a self-referential edge loop.
---@param graph_direction dotfiles.mermaid.graph_renderer.GraphDirection the graph direction that decides which loop orientation to prefer.
---@return dotfiles.mermaid.graph_renderer.Direction preferred_dir the preferred direction to leave the source node.
---@return dotfiles.mermaid.graph_renderer.Direction preferred_opposite the preferred direction to enter the target node.
---@return dotfiles.mermaid.graph_renderer.Direction alternative_dir the fallback direction to leave the source node.
---@return dotfiles.mermaid.graph_renderer.Direction alternative_opposite the fallback direction to enter the target node.
local function self_reference_direction(graph_direction)
  if graph_direction == "LR" then
    return Directions.right, Directions.down, Directions.down, Directions.right
  end
  return Directions.down, Directions.right, Directions.right, Directions.down
end

---Choose preferred and fallback attachment directions for a normal edge.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge whose source and target attachments should be chosen.
---@param graph_direction dotfiles.mermaid.graph_renderer.GraphDirection the graph direction that biases the routing choice.
---@return dotfiles.mermaid.graph_renderer.Direction preferred_dir the preferred direction to leave the source node.
---@return dotfiles.mermaid.graph_renderer.Direction preferred_opposite the preferred direction to enter the target node.
---@return dotfiles.mermaid.graph_renderer.Direction alternative_dir the fallback direction to leave the source node.
---@return dotfiles.mermaid.graph_renderer.Direction alternative_opposite the fallback direction to enter the target node.
local function determine_start_and_end_dir(edge, graph_direction)
  if edge.from == edge.to then
    return self_reference_direction(graph_direction)
  end

  local direction = geometry.determine_direction(assert(edge.from.grid_coord), assert(edge.to.grid_coord))
  local backwards = graph_direction == "LR"
      and (geometry.same_direction(direction, Directions.left) or geometry.same_direction(
        direction,
        Directions.upper_left
      ) or geometry.same_direction(direction, Directions.lower_left))
    or graph_direction == "TD"
      and (geometry.same_direction(direction, Directions.up) or geometry.same_direction(
        direction,
        Directions.upper_left
      ) or geometry.same_direction(direction, Directions.upper_right))

  local preferred_dir, preferred_opposite, alternative_dir, alternative_opposite

  if geometry.same_direction(direction, Directions.lower_right) then
    if graph_direction == "LR" then
      preferred_dir, preferred_opposite = Directions.down, Directions.left
      alternative_dir, alternative_opposite = Directions.right, Directions.up
    else
      preferred_dir, preferred_opposite = Directions.right, Directions.up
      alternative_dir, alternative_opposite = Directions.down, Directions.left
    end
  elseif geometry.same_direction(direction, Directions.upper_right) then
    if graph_direction == "LR" then
      preferred_dir, preferred_opposite = Directions.up, Directions.left
      alternative_dir, alternative_opposite = Directions.right, Directions.down
    else
      preferred_dir, preferred_opposite = Directions.right, Directions.down
      alternative_dir, alternative_opposite = Directions.up, Directions.left
    end
  elseif geometry.same_direction(direction, Directions.lower_left) then
    if graph_direction == "LR" then
      preferred_dir, preferred_opposite = Directions.down, Directions.down
      alternative_dir, alternative_opposite = Directions.left, Directions.up
    else
      preferred_dir, preferred_opposite = Directions.left, Directions.up
      alternative_dir, alternative_opposite = Directions.down, Directions.right
    end
  elseif geometry.same_direction(direction, Directions.upper_left) then
    if graph_direction == "LR" then
      preferred_dir, preferred_opposite = Directions.down, Directions.down
      alternative_dir, alternative_opposite = Directions.left, Directions.down
    else
      preferred_dir, preferred_opposite = Directions.right, Directions.right
      alternative_dir, alternative_opposite = Directions.up, Directions.right
    end
  elseif backwards then
    if graph_direction == "LR" and geometry.same_direction(direction, Directions.left) then
      preferred_dir, preferred_opposite = Directions.down, Directions.down
      alternative_dir, alternative_opposite = Directions.left, Directions.right
    elseif graph_direction == "TD" and geometry.same_direction(direction, Directions.up) then
      preferred_dir, preferred_opposite = Directions.right, Directions.right
      alternative_dir, alternative_opposite = Directions.up, Directions.down
    else
      preferred_dir, preferred_opposite = direction, geometry.opposite_direction(direction)
      alternative_dir, alternative_opposite = direction, geometry.opposite_direction(direction)
    end
  else
    preferred_dir, preferred_opposite = direction, geometry.opposite_direction(direction)
    alternative_dir, alternative_opposite = direction, geometry.opposite_direction(direction)
  end

  return preferred_dir, preferred_opposite, alternative_dir, alternative_opposite
end

---Choose attachment directions for edges that leave branching pseudostates.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge whose branching source may need custom attachment directions.
---@param effective_direction dotfiles.mermaid.graph_renderer.GraphDirection the routing direction that applies around the source node.
---@return dotfiles.mermaid.graph_renderer.Direction|nil preferred_dir the preferred direction to leave the source node, or nil when special handling is not needed.
---@return dotfiles.mermaid.graph_renderer.Direction|nil preferred_opposite the preferred direction to enter the target node, or nil when special handling is not needed.
---@return dotfiles.mermaid.graph_renderer.Direction|nil alternative_dir the fallback direction to leave the source node, or nil when special handling is not needed.
---@return dotfiles.mermaid.graph_renderer.Direction|nil alternative_opposite the fallback direction to enter the target node, or nil when special handling is not needed.
local function determine_branching_pseudostate_dirs(edge, effective_direction)
  if not geometry.is_branching_pseudostate(edge.from.shape) then
    return nil
  end

  local from_grid = assert(edge.from.grid_coord)
  local to_grid = assert(edge.to.grid_coord)

  if effective_direction == "LR" then
    if to_grid.y < from_grid.y then
      return Directions.up, Directions.left, Directions.right, Directions.left
    end
    if to_grid.y > from_grid.y then
      return Directions.down, Directions.left, Directions.right, Directions.left
    end
    return Directions.right, Directions.left, Directions.right, Directions.left
  end

  if to_grid.x < from_grid.x then
    return Directions.left, Directions.up, Directions.down, Directions.up
  end
  if to_grid.x > from_grid.x then
    return Directions.right, Directions.up, Directions.down, Directions.up
  end
  return Directions.down, Directions.up, Directions.down, Directions.up
end

---Choose and assign the routed path and attachment directions for a single edge.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose grid occupancy and direction rules guide routing.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge whose path and attachment directions should be populated.
local function determine_path(graph, edge)
  local source_subgraph = get_node_subgraph(graph, edge.from)
  local target_subgraph = get_node_subgraph(graph, edge.to)
  local effective_direction = source_subgraph
      and source_subgraph == target_subgraph
      and get_effective_direction(graph, edge.from)
    or graph.config.graph_direction
  local preferred_dir, preferred_opposite, alternative_dir, alternative_opposite =
    determine_branching_pseudostate_dirs(edge, effective_direction)

  if not preferred_dir or not preferred_opposite or not alternative_dir or not alternative_opposite then
    preferred_dir, preferred_opposite, alternative_dir, alternative_opposite =
      determine_start_and_end_dir(edge, effective_direction)
  end

  local preferred_from = geometry.move_grid_coord(assert(edge.from.grid_coord), preferred_dir)
  local preferred_to = geometry.move_grid_coord(assert(edge.to.grid_coord), preferred_opposite)
  local preferred_path = get_path(graph.grid, preferred_from, preferred_to)

  local alternative_from = geometry.move_grid_coord(assert(edge.from.grid_coord), alternative_dir)
  local alternative_to = geometry.move_grid_coord(assert(edge.to.grid_coord), alternative_opposite)
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

---Measure the rendered column width available along a line segment.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose column widths define the rendered span.
---@param line dotfiles.mermaid.graph_renderer.GridPath the two-point grid segment whose width should be measured.
---@return integer total the total rendered width available across the segment.
local function calculate_line_width(graph, line)
  local total = 0
  local start_x = math.min(line[1].x, line[2].x)
  local end_x = math.max(line[1].x, line[2].x)
  for x = start_x, end_x do
    total = total + (graph.column_width[x] or 0)
  end
  return total
end

---Pick the best path segment to host an edge label and reserve the needed width.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose column widths may be expanded for the label.
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge whose label placement should be determined.
local function determine_label_line(graph, edge)
  if edge.text == "" then
    return
  end

  if geometry.is_branching_pseudostate(edge.from.shape) then
    edge.has_branch_label = true
    edge.label_line = {}
    return
  end

  local segments = {}
  for index = 2, #edge.path do
    local line = { edge.path[index - 1], edge.path[index] }
    segments[#segments + 1] = {
      line = line,
      width = calculate_line_width(graph, line),
      index = index,
      is_horizontal = line[1].y == line[2].y,
    }
  end

  local function sort_candidate_segments(candidates)
    table.sort(candidates, function(left, right)
      if left.is_horizontal ~= right.is_horizontal then
        return left.is_horizontal
      end
      if left.width ~= right.width then
        return left.width > right.width
      end
      return left.index > right.index
    end)
  end

  local suitable = {}
  for _, segment in ipairs(segments) do
    if segment.width >= text.char_len(edge.text) and segment.index > 2 then
      suitable[#suitable + 1] = segment
    end
  end

  sort_candidate_segments(suitable)

  local chosen = suitable[1]
  if not chosen then
    local fallback = {}
    for _, segment in ipairs(segments) do
      if segment.width >= text.char_len(edge.text) then
        fallback[#fallback + 1] = segment
      end
    end
    sort_candidate_segments(fallback)
    chosen = fallback[1]
  end

  if not chosen then
    table.sort(segments, function(left, right)
      if left.is_horizontal ~= right.is_horizontal then
        return left.is_horizontal
      end
      if left.width ~= right.width then
        return left.width > right.width
      end
      return left.index > right.index
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

---Group compatible edges into reusable fan-in or fan-out bundles.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose edges should be analyzed for bundling.
---@return dotfiles.mermaid.graph_renderer.EdgeBundle[] bundles the bundle definitions discovered for compatible edges.
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
      if geometry.is_state_pseudostate(edge.from.shape) or geometry.is_state_pseudostate(edge.to.shape) then
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
          junction_dir = Directions.middle,
          shared_node_dir = Directions.middle,
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
        junction_dir = Directions.middle,
        shared_node_dir = Directions.middle,
      }
      for _, edge in ipairs(edges) do
        edge.bundle = bundle
      end
      bundles[#bundles + 1] = bundle
    end
  end

  return bundles
end

---Choose the grid coordinate where a bundle's shared trunk meets its branches.
---@param bundle dotfiles.mermaid.graph_renderer.EdgeBundle the bundle whose junction coordinate should be computed.
---@return dotfiles.mermaid.graph_renderer.GridCoord junction_point the grid coordinate that will serve as the bundle junction.
local function calculate_junction_point(bundle)
  local shared_coord = assert(bundle.shared_node.grid_coord)
  if bundle.type == "fan-in" then
    return { x = shared_coord.x + 1, y = shared_coord.y - 1 }
  end
  return { x = shared_coord.x + 1, y = shared_coord.y + 3 }
end

---Populate shared and per-edge paths for every edge in a bundle.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose grid occupancy guides bundled routing.
---@param bundle dotfiles.mermaid.graph_renderer.EdgeBundle the bundle whose shared and branch paths should be assigned.
local function route_bundled_edges(graph, bundle)
  local direction = graph.config.graph_direction
  bundle.junction_point = calculate_junction_point(bundle)
  local junction = assert(bundle.junction_point)

  if bundle.type == "fan-in" then
    bundle.junction_dir = direction == "TD" and Directions.up or Directions.left
    bundle.shared_node_dir = direction == "TD" and Directions.down or Directions.right

    local target_coord = assert(bundle.shared_node.grid_coord)
    local target_entry = direction == "TD" and { x = target_coord.x + 1, y = target_coord.y }
      or { x = target_coord.x, y = target_coord.y + 1 }
    local shared_path = get_path(graph.grid, junction, target_entry)
    bundle.shared_path = shared_path and merge_path(shared_path) or { junction, target_entry }

    for _, edge in ipairs(bundle.edges) do
      local source_coord = assert(edge.from.grid_coord)
      local source_exit = direction == "TD" and { x = source_coord.x + 1, y = source_coord.y + 2 }
        or { x = source_coord.x + 2, y = source_coord.y + 1 }
      local path_to_junction = get_path(graph.grid, source_exit, junction)
      edge.path_to_junction = path_to_junction and merge_path(path_to_junction) or { source_exit, junction }
      edge.start_dir = direction == "TD" and Directions.down or Directions.right
      edge.end_dir = direction == "TD" and Directions.up or Directions.left
      edge.path = {}
      for _, coord in ipairs(edge.path_to_junction) do
        edge.path[#edge.path + 1] = coord
      end
      for index = 2, #bundle.shared_path do
        edge.path[#edge.path + 1] = bundle.shared_path[index]
      end
    end
    return
  end

  bundle.junction_dir = direction == "TD" and Directions.down or Directions.right
  bundle.shared_node_dir = direction == "TD" and Directions.up or Directions.left

  local source_coord = assert(bundle.shared_node.grid_coord)
  local source_exit = direction == "TD" and { x = source_coord.x + 1, y = source_coord.y + 2 }
    or { x = source_coord.x + 2, y = source_coord.y + 1 }
  local shared_path = get_path(graph.grid, source_exit, junction)
  bundle.shared_path = shared_path and merge_path(shared_path) or { source_exit, junction }

  for _, edge in ipairs(bundle.edges) do
    local target_coord = assert(edge.to.grid_coord)
    local target_entry = direction == "TD" and { x = target_coord.x + 1, y = target_coord.y }
      or { x = target_coord.x, y = target_coord.y + 1 }
    local path_to_junction = get_path(graph.grid, junction, target_entry)
    edge.path_to_junction = path_to_junction and merge_path(path_to_junction) or { junction, target_entry }
    edge.start_dir = direction == "TD" and Directions.down or Directions.right
    edge.end_dir = direction == "TD" and Directions.up or Directions.left
    edge.path = {}
    for _, coord in ipairs(bundle.shared_path) do
      edge.path[#edge.path + 1] = coord
    end
    for index = 2, #edge.path_to_junction do
      edge.path[#edge.path + 1] = edge.path_to_junction[index]
    end
  end
end

---Route every previously analyzed edge bundle in the graph.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose bundles should be routed.
local function process_bundles(graph)
  for _, bundle in ipairs(graph.bundles) do
    route_bundled_edges(graph, bundle)
  end
end

---Reserve routing space, build bundles, and compute final paths and label segments for every edge.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the layout graph whose edges should be fully prepared for drawing.
local function prepare_edge_routes(graph)
  for _, node in ipairs(graph.nodes) do
    set_column_width(graph, node)
  end

  graph.bundles = analyze_edge_bundles(graph)
  process_bundles(graph)

  for _, edge in ipairs(graph.edges) do
    if not (edge.bundle and #edge.path > 0) then
      determine_path(graph, edge)
    end
    increase_grid_size_for_path(graph, edge.path)
    determine_label_line(graph, edge)
  end
end

local M = {}
M.get_effective_direction = get_effective_direction
M.get_children = get_children
M.node_in_subgraph = node_in_subgraph
M.prepare_edge_routes = prepare_edge_routes
return M
