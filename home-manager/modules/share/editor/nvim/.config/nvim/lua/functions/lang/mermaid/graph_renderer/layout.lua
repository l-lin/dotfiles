local text = require("functions.lang.mermaid.text")
local geometry = require("functions.lang.mermaid.graph_renderer.geometry")
local routing = require("functions.lang.mermaid.graph_renderer.route")

---Stage 2: clone the normalized graph into mutable layout state, assign grid
---slots, route edges, and compute all drawing coordinates.
---
---The key invariant for the draw stage is simple: by the time
---`prepare_layout()` returns, every node knows where it lives in both grid
---space and drawing space, every edge already owns its routed path, and
---every subgraph/note already knows its bounds.
---Drawing should therefore be a mostly mechanical translation to canvas
---glyphs.

---Clone the normalized nodes into layout nodes, preserving the original node
---order.
---@param source_nodes dotfiles.mermaid.graph_renderer.NormalizedNode[] the normalized nodes to clone
---@return dotfiles.mermaid.graph_renderer.LayoutNode[] nodes the cloned layout nodes
---@return table<string, dotfiles.mermaid.graph_renderer.LayoutNode> node_by_name a lookup table mapping node names to their corresponding layout nodes
local function clone_nodes(source_nodes)
  ---@type dotfiles.mermaid.graph_renderer.LayoutNode[]
  local nodes = {}
  ---@type table<string, dotfiles.mermaid.graph_renderer.LayoutNode>
  local node_by_name = {}

  for _, source_node in ipairs(source_nodes) do
    ---@type dotfiles.mermaid.graph_renderer.LayoutNode
    local node = {
      name = source_node.name,
      display_label = source_node.display_label,
      shape = source_node.shape,
      index = source_node.index,
      layout_direction = nil,
      dimensions = nil,
      grid_coord = nil,
      drawing_coord = nil,
    }
    nodes[#nodes + 1] = node
    node_by_name[node.name] = node
  end

  return nodes, node_by_name
end

---Clone the normalized subgraph into a layout subgraph, recursively cloning
---children and adding them to the list of all subgraphs and the lookup table
---by ID.
---@param source_subgraph dotfiles.mermaid.graph_renderer.NormalizedSubgraph the normalized subgraph to clone
---@param parent dotfiles.mermaid.graph_renderer.LayoutSubgraph|nil the parent layout subgraph, or nil if this is a root subgraph
---@param node_by_name table<string, dotfiles.mermaid.graph_renderer.LayoutNode> the lookup table mapping node names to their corresponding layout nodes
---@param all_subgraphs dotfiles.mermaid.graph_renderer.LayoutSubgraph[] the list of all layout subgraphs, to which the cloned subgraph will be added
---@param subgraph_by_id table<string, dotfiles.mermaid.graph_renderer.LayoutSubgraph> the lookup table mapping subgraph IDs to their corresponding layout subgraphs, to which the cloned subgraph will be added
---@return dotfiles.mermaid.graph_renderer.LayoutSubgraph subgraph the cloned layout subgraph
local function clone_subgraph(source_subgraph, parent, node_by_name, all_subgraphs, subgraph_by_id)
  ---@type dotfiles.mermaid.graph_renderer.LayoutSubgraph
  local subgraph = {
    id = source_subgraph.id,
    name = source_subgraph.name,
    kind = source_subgraph.kind,
    parent = parent,
    children = {},
    nodes = {},
    direction = source_subgraph.direction,
    depth = source_subgraph.depth,
    min_x = 0,
    min_y = 0,
    max_x = 0,
    max_y = 0,
  }

  for _, source_node in ipairs(source_subgraph.nodes) do
    local node = node_by_name[source_node.name]
    if node then
      subgraph.nodes[#subgraph.nodes + 1] = node
    end
  end

  all_subgraphs[#all_subgraphs + 1] = subgraph
  subgraph_by_id[subgraph.id] = subgraph

  for _, child_source in ipairs(source_subgraph.children) do
    subgraph.children[#subgraph.children + 1] =
      clone_subgraph(child_source, subgraph, node_by_name, all_subgraphs, subgraph_by_id)
  end

  return subgraph
end

---Build an index mapping each node to its innermost containing subgraph, if
---any.
---@param subgraphs dotfiles.mermaid.graph_renderer.LayoutSubgraph[] the list of all layout subgraphs to index
---@return table<dotfiles.mermaid.graph_renderer.LayoutNode, dotfiles.mermaid.graph_renderer.LayoutSubgraph> index a lookup table mapping each layout node to its innermost containing layout subgraph, if any
local function build_innermost_subgraph_index(subgraphs)
  ---@type table<dotfiles.mermaid.graph_renderer.LayoutNode, dotfiles.mermaid.graph_renderer.LayoutSubgraph>
  local index = {}

  for _, subgraph in ipairs(subgraphs) do
    for _, node in ipairs(subgraph.nodes) do
      local current = index[node]
      if not current or current.depth < subgraph.depth then
        index[node] = subgraph
      end
    end
  end

  return index
end

---Clone the normalized edges into layout edges, preserving the original edge
---order.
---@param source_edges dotfiles.mermaid.graph_renderer.NormalizedEdge[] the normalized edges to clone
---@param node_by_name table<string, dotfiles.mermaid.graph_renderer.LayoutNode> the lookup table mapping node names to their corresponding layout nodes
---@return dotfiles.mermaid.graph_renderer.LayoutEdge[] edges the cloned layout edges
local function clone_edges(source_edges, node_by_name)
  ---@type dotfiles.mermaid.graph_renderer.LayoutEdge[]
  local edges = {}

  for _, source_edge in ipairs(source_edges) do
    ---@type dotfiles.mermaid.graph_renderer.LayoutEdge
    local edge = {
      from = assert(node_by_name[source_edge.from.name]),
      to = assert(node_by_name[source_edge.to.name]),
      text = source_edge.text,
      style = source_edge.style,
      has_arrow_start = source_edge.has_arrow_start,
      has_arrow_end = source_edge.has_arrow_end,
      source_composite_id = source_edge.source_composite_id,
      target_composite_id = source_edge.target_composite_id,
      path = {},
      draw_path = nil,
      label_line = {},
      start_dir = geometry.Directions.middle,
      end_dir = geometry.Directions.middle,
      has_branch_label = nil,
      bundle = nil,
      path_to_junction = nil,
      start_attachment_override = nil,
      end_attachment_override = nil,
    }
    edges[#edges + 1] = edge
  end

  return edges
end

---Clone the normalized notes into layout notes, preserving the original note
---order.
---@param source_notes dotfiles.mermaid.graph_renderer.NormalizedNote[] the normalized notes to clone
---@param node_by_name table<string, dotfiles.mermaid.graph_renderer.LayoutNode> the lookup table mapping node names to their corresponding layout nodes
---@return dotfiles.mermaid.graph_renderer.LayoutNote[] notes the cloned layout notes
local function clone_notes(source_notes, node_by_name)
  ---@type dotfiles.mermaid.graph_renderer.LayoutNote[]
  local notes = {}

  for _, source_note in ipairs(source_notes) do
    ---@type dotfiles.mermaid.graph_renderer.LayoutNote
    local note = {
      node = assert(node_by_name[source_note.node.name]),
      position = source_note.position,
      text = source_note.text,
      width = nil,
      height = nil,
      offset = nil,
    }
    notes[#notes + 1] = note
  end

  return notes
end

---Create a working layout graph from the normalized graph, cloning nodes,
---edges, subgraphs, and notes,
---@param normalized dotfiles.mermaid.graph_renderer.NormalizedGraph the normalized graph to clone into a working layout graph
---@return dotfiles.mermaid.graph_renderer.LayoutGraph layout_graph the working layout graph with cloned nodes, edges, subgraphs, and notes
local function create_working_layout(normalized)
  local nodes, node_by_name = clone_nodes(normalized.nodes)

  ---@type dotfiles.mermaid.graph_renderer.LayoutSubgraph[]
  local subgraphs = {}
  ---@type table<string, dotfiles.mermaid.graph_renderer.LayoutSubgraph>
  local subgraph_by_id = {}

  for _, source_subgraph in ipairs(normalized.subgraphs) do
    if source_subgraph.parent == nil then
      clone_subgraph(source_subgraph, nil, node_by_name, subgraphs, subgraph_by_id)
    end
  end

  return {
    nodes = nodes,
    edges = clone_edges(normalized.edges, node_by_name),
    subgraphs = subgraphs,
    subgraph_by_id = subgraph_by_id,
    innermost_subgraph_by_node = build_innermost_subgraph_index(subgraphs),
    notes = clone_notes(normalized.notes, node_by_name),
    grid = {},
    column_width = {},
    row_height = {},
    config = {
      padding_x = normalized.config.padding_x,
      padding_y = normalized.config.padding_y,
      box_border_padding = normalized.config.box_border_padding,
      graph_direction = normalized.config.graph_direction,
    },
    offset_x = 0,
    offset_y = 0,
    bundles = {},
    parsed_direction = normalized.parsed_direction,
    canvas_max_x = 0,
    canvas_max_y = 0,
  }
end

---Reserve a spot in the grid for a node, recursively searching for the next
---available spot if the requested spot is already occupied.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the grid and nodes
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the node to place in the grid
---@param requested dotfiles.mermaid.graph_renderer.GridCoord the requested grid coordinates for the node
---@param effective_direction dotfiles.mermaid.graph_renderer.GraphDirection|nil the effective direction of the graph, used to determine how to search for the next available spot if the requested spot is occupied
---@return dotfiles.mermaid.graph_renderer.GridCoord requested the final grid coordinates where the node was placed
local function reserve_spot_in_grid(graph, node, requested, effective_direction)
  local direction = effective_direction or routing.get_effective_direction(graph, node)
  node.layout_direction = direction

  if graph.grid[geometry.grid_key(requested)] then
    if direction == "LR" then
      return reserve_spot_in_grid(graph, node, { x = requested.x, y = requested.y + 4 }, direction)
    end
    return reserve_spot_in_grid(graph, node, { x = requested.x + 4, y = requested.y }, direction)
  end

  for dx = 0, 2 do
    for dy = 0, 2 do
      graph.grid[geometry.grid_key({ x = requested.x + dx, y = requested.y + dy })] = node
    end
  end

  node.grid_coord = requested
  return requested
end

---Measure the dimensions of each node in the graph, storing the results in the node's `dimensions` field.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the nodes to measure
local function measure_nodes(graph)
  for _, node in ipairs(graph.nodes) do
    node.dimensions = geometry.measure_node(node, graph.config)
  end
end

---Place nodes in the grid, starting with root nodes and recursively placing
---child nodes based on their parent nodes' positions and the effective
---direction of the graph.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the nodes to place
local function place_nodes(graph)
  local highest_position_per_level = {}
  for index = 0, 100 do
    highest_position_per_level[index] = 0
  end

  local uses_state_regions_or_pseudostates = false
  local has_branching_pseudostates = false
  for _, node in ipairs(graph.nodes) do
    if node.shape == "state-choice" or node.shape == "state-fork" or node.shape == "state-join" then
      uses_state_regions_or_pseudostates = true
      if geometry.is_branching_pseudostate(node.shape) then
        has_branching_pseudostates = true
      end
      break
    end
  end

  if not uses_state_regions_or_pseudostates then
    for _, subgraph in ipairs(graph.subgraphs) do
      if subgraph.kind == "region" then
        uses_state_regions_or_pseudostates = true
        break
      end
    end
  end

  local initial_roots = {}
  if uses_state_regions_or_pseudostates then
    local incoming_edges = {}
    for _, edge in ipairs(graph.edges) do
      if not routing.targets_concurrent_composite(graph, edge) then
        incoming_edges[edge.to] = (incoming_edges[edge.to] or 0) + 1
      end
    end

    for _, node in ipairs(graph.nodes) do
      if not incoming_edges[node] then
        initial_roots[#initial_roots + 1] = node
      end
    end
  else
    local nodes_found = {}
    for _, node in ipairs(graph.nodes) do
      if not nodes_found[node.name] then
        initial_roots[#initial_roots + 1] = node
      end
      nodes_found[node.name] = true
      for _, child in ipairs(routing.get_children(graph, node)) do
        nodes_found[child.name] = true
      end
    end
  end

  if #initial_roots == 0 then
    for _, node in ipairs(graph.nodes) do
      initial_roots[#initial_roots + 1] = node
    end
  end

  local root_nodes = {}
  for _, node in ipairs(initial_roots) do
    local node_subgraph = graph.innermost_subgraph_by_node[node]
    if not node_subgraph then
      root_nodes[#root_nodes + 1] = node
    else
      local external_incoming = false
      for _, edge in ipairs(graph.edges) do
        if
          edge.to == node
          and not routing.targets_concurrent_composite(graph, edge)
          and graph.innermost_subgraph_by_node[edge.from] ~= node_subgraph
        then
          external_incoming = true
          break
        end
      end
      if not external_incoming then
        root_nodes[#root_nodes + 1] = node
      end
    end
  end

  if #root_nodes == 0 then
    for _, node in ipairs(initial_roots) do
      root_nodes[#root_nodes + 1] = node
    end
  end

  local has_external_roots = false
  local has_subgraph_roots_with_edges = false
  for _, node in ipairs(root_nodes) do
    if routing.node_in_subgraph(graph, node) then
      if #routing.get_children(graph, node) > 0 then
        has_subgraph_roots_with_edges = true
      end
    else
      has_external_roots = true
    end
  end
  local external_roots = {}
  local subgraph_roots = {}
  for _, node in ipairs(root_nodes) do
    if routing.node_in_subgraph(graph, node) then
      subgraph_roots[#subgraph_roots + 1] = node
    else
      external_roots[#external_roots + 1] = node
    end
  end

  local should_separate = has_external_roots
    and has_subgraph_roots_with_edges
    and (graph.config.graph_direction == "LR" or #subgraph_roots > 1)

  if not should_separate then
    external_roots = root_nodes
    subgraph_roots = {}
  end

  local root_lane_offset = has_branching_pseudostates and 4 or 0

  for _, node in ipairs(external_roots) do
    local root_direction = routing.get_effective_direction(graph, node)
    local requested = root_direction == "LR" and { x = 0, y = highest_position_per_level[0] + root_lane_offset }
      or { x = highest_position_per_level[0] + root_lane_offset, y = 0 }
    reserve_spot_in_grid(graph, node, requested, root_direction)
    highest_position_per_level[0] = highest_position_per_level[0] + 4
  end

  if should_separate and #subgraph_roots > 0 then
    local separated_td_x = highest_position_per_level[0] + root_lane_offset

    for _, node in ipairs(subgraph_roots) do
      local root_direction = routing.get_effective_direction(graph, node)
      local requested
      if root_direction == "LR" then
        requested = { x = 4, y = highest_position_per_level[4] }
        highest_position_per_level[4] = highest_position_per_level[4] + 4
      else
        requested = { x = separated_td_x, y = 4 }
        separated_td_x = separated_td_x + 4
      end
      reserve_spot_in_grid(graph, node, requested, root_direction)
    end
  end

  local placed_count = #external_roots + #subgraph_roots
  while placed_count < #graph.nodes do
    local previous_count = placed_count
    for _, node in ipairs(graph.nodes) do
      local grid_coord = node.grid_coord
      if grid_coord then
        local children = routing.get_children(graph, node)
        for child_index, child in ipairs(children) do
          if not child.grid_coord then
            local parent_subgraph = graph.innermost_subgraph_by_node[node]
            local child_subgraph = graph.innermost_subgraph_by_node[child]
            local same_subgraph = parent_subgraph and parent_subgraph == child_subgraph
            local edge_direction = same_subgraph and routing.get_effective_direction(graph, node)
              or graph.config.graph_direction
            local child_level = edge_direction == "LR" and (grid_coord.x + 4) or (grid_coord.y + 4)
            local highest_position
            if same_subgraph then
              highest_position = edge_direction == "LR" and grid_coord.y or grid_coord.x
            elseif
              edge_direction ~= graph.config.graph_direction or (has_branching_pseudostates and #children == 1)
            then
              highest_position = edge_direction == "LR" and grid_coord.y or grid_coord.x
            else
              highest_position = highest_position_per_level[child_level] or 0
            end

            if geometry.is_branching_pseudostate(node.shape) then
              local branch_base = edge_direction == "LR" and grid_coord.y or grid_coord.x
              local branch_offset = (#children - 1) * 4
              highest_position = branch_base - branch_offset + ((child_index - 1) * 8)
              if highest_position < 0 then
                highest_position = (child_index - 1) * 8
              end
            end

            local requested = edge_direction == "LR" and { x = child_level, y = highest_position }
              or { x = highest_position, y = child_level }
            reserve_spot_in_grid(graph, child, requested, edge_direction)
            if edge_direction == graph.config.graph_direction and not geometry.is_branching_pseudostate(node.shape) then
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
end

---Grid coordinates are the logical coordinates of nodes in the grid, while
---drawing coordinates are the actual pixel coordinates on the canvas. This
---function converts grid coordinates to drawing coordinates, taking into
---account the column widths, row heights, and any offsets applied to the graph.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the grid and drawing information
---@param coord dotfiles.mermaid.graph_renderer.GridCoord the grid coordinates to convert to drawing coordinates
---@param direction dotfiles.mermaid.graph_renderer.Direction|nil the direction to offset the drawing coordinates, if any (optional)
---@return dotfiles.mermaid.graph_renderer.DrawingCoord drawing_coord the calculated drawing coordinates corresponding to the given grid coordinates, optionally offset by the specified direction
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

---Calculate the rendered size of a node in the graph, based on its grid
---coordinates and the column widths and row heights of the graph. The
---rendered size includes the width and height of the node, taking into
---account any padding or spacing defined in the graph's configuration.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the grid and drawing information
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the node for which to calculate the rendered size
---@return { width: integer, height: integer } size the calculated rendered size of the node, including width and height
local function node_render_size(graph, node)
  local grid_coord = assert(node.grid_coord, "node must be placed before size lookup")
  return {
    width = (graph.column_width[grid_coord.x] or 0) + (graph.column_width[grid_coord.x + 1] or 0) + 1,
    height = (graph.row_height[grid_coord.y] or 0) + (graph.row_height[grid_coord.y + 1] or 0) + 1,
  }
end

---Calculate the attachment point for a node in the graph, based on its
---drawing coordinates and the specified direction. The attachment point is
---the point on the node's boundary where an edge should connect, taking into
---account the node's rendered size and any offsets applied to the graph.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the grid and drawing information
---@param node dotfiles.mermaid.graph_renderer.LayoutNode the node for which to calculate the attachment point
---@param direction dotfiles.mermaid.graph_renderer.Direction the direction in which the attachment point should be calculated (e.g., "up", "down", "left", "right")
---@return dotfiles.mermaid.graph_renderer.DrawingCoord drawing_coord the calculated attachment point on the node's boundary, based on its drawing coordinates and the specified direction
local function node_attachment_point(graph, node, direction)
  local base_coord = assert(node.drawing_coord, "node must have drawing coordinates before attachment lookup")
  return geometry.shape_attachment_point(node, direction, node_render_size(graph, node), base_coord)
end

---Assign drawing coordinates to each node in the graph, based on their grid
---coordinates and the column widths and row heights of the graph. This
---function iterates over all nodes in the graph and calculates their drawing
---coordinates using the `grid_to_drawing_coord` function, storing the
---results in each node's `drawing_coord` field.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the nodes to assign drawing coordinates to
local function assign_drawing_coordinates(graph)
  for _, node in ipairs(graph.nodes) do
    node.drawing_coord = grid_to_drawing_coord(graph, assert(node.grid_coord))
  end
end

---Calculate the bounding box for a subgraph, based on the drawing
---coordinates of its child nodes and any nested subgraphs. This function
---recursively calculates the minimum and maximum x and y coordinates of all
---nodes and subgraphs within the specified subgraph, taking into account any
---padding or spacing defined in the graph's configuration. The resulting
---bounding box is stored in the subgraph's `min_x`, `min_y`, `max_x`, and
---`max_y` fields.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the subgraph and its child nodes
---@param subgraph dotfiles.mermaid.graph_renderer.LayoutSubgraph the subgraph for which to calculate the bounding box
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
    local node_coord = node.drawing_coord
    if node_coord then
      local rendered_size = node_render_size(graph, node)
      local node_max_x = node_coord.x + rendered_size.width - 1
      local node_max_y = node_coord.y + rendered_size.height - 1
      min_x = math.min(min_x, node_coord.x)
      min_y = math.min(min_y, node_coord.y)
      max_x = math.max(max_x, node_max_x)
      max_y = math.max(max_y, node_max_y)
    end
  end

  local horizontal_padding = subgraph.kind == "region" and 1 or 2
  local top_padding = subgraph.kind == "region" and 2 or 4
  local bottom_padding = subgraph.kind == "region" and 1 or 2

  min_x = min_x - horizontal_padding
  min_y = min_y - top_padding
  max_x = max_x + horizontal_padding
  max_y = max_y + bottom_padding

  local minimum_width = 4
  for _, line in ipairs(text.split_lines(subgraph.name or "")) do
    minimum_width = math.max(minimum_width, text.char_len(line) + 4)
  end

  local width = max_x - min_x
  if width < minimum_width then
    local extra_width = minimum_width - width
    local left_extra = math.floor(extra_width / 2)
    local right_extra = extra_width - left_extra
    min_x = min_x - left_extra
    max_x = max_x + right_extra
  end

  subgraph.min_x = min_x
  subgraph.min_y = min_y
  subgraph.max_x = max_x
  subgraph.max_y = max_y
end

---Ensure that subgraphs do not overlap by adjusting their bounding boxes if
---necessary. This function iterates over all root subgraphs in the graph and
---checks for overlaps between their bounding boxes. If an overlap is
---detected, the function adjusts the positions of the overlapping subgraphs
---to create sufficient spacing between them, ensuring that they do not
---visually collide in the rendered output.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the subgraphs to check for overlaps
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
          local offset = (left.max_y + 2) - right.min_y
          right.min_y = right.min_y + offset
          right.max_y = right.max_y + offset
        elseif right.max_y >= left.min_y - 1 and right.min_y < left.min_y then
          local offset = (right.max_y + 2) - left.min_y
          left.min_y = left.min_y + offset
          left.max_y = left.max_y + offset
        end
      end

      if left.min_y < right.max_y and left.max_y > right.min_y then
        if left.max_x >= right.min_x - 1 and left.min_x < right.min_x then
          local offset = (left.max_x + 2) - right.min_x
          right.min_x = right.min_x + offset
          right.max_x = right.max_x + offset
        elseif right.max_x >= left.min_x - 1 and right.min_x < left.min_x then
          local offset = (right.max_x + 2) - left.min_x
          left.min_x = left.min_x + offset
          left.max_x = left.max_x + offset
        end
      end
    end
  end
end

---Calculate the bounding boxes for all subgraphs in the graph, ensuring that
---they do not overlap and that they are properly sized to contain their
---child nodes and any nested subgraphs. This function iterates over all root
---subgraphs in the graph and calls `calculate_subgraph_bounding_box` for
---each one, followed by a call to `ensure_subgraph_spacing` to adjust any
---overlapping subgraphs.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the subgraphs to calculate bounding boxes for
local function calculate_subgraph_bounding_boxes(graph)
  for _, subgraph in ipairs(graph.subgraphs) do
    if subgraph.parent == nil then
      calculate_subgraph_bounding_box(graph, subgraph)
    end
  end
  ensure_subgraph_spacing(graph)
end

---Calculate the bounding boxes for all notes in the graph, ensuring that they
---are properly sized to contain their text and that they are positioned
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the notes to calculate bounding boxes for
---@param offset_x integer the x-offset to apply to the notes' positions, if any
---@param offset_y integer the y-offset to apply to the notes' positions, if any
local function offset_graph_drawing(graph, offset_x, offset_y)
  if offset_x == 0 and offset_y == 0 then
    return
  end

  graph.offset_x = graph.offset_x + offset_x
  graph.offset_y = graph.offset_y + offset_y

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

  for _, note in ipairs(graph.notes) do
    if note.offset then
      note.offset.x = note.offset.x + offset_x
      note.offset.y = note.offset.y + offset_y
    end
  end
end

---Calculate the minimum x and y coordinates of all subgraphs in the graph,
---and offset the entire graph drawing so that all subgraphs are positioned
---at or above the origin (0, 0). This function iterates over all subgraphs
---in the graph, finds the minimum x and y coordinates, and then calls
---`offset_graph_drawing` to adjust the positions of all nodes, subgraphs,
---and notes accordingly.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the subgraphs to offset
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

  offset_graph_drawing(graph, -min_x, -min_y)
end

---Check if a given point is inside the bounding box of a subgraph. This
---function takes into account the minimum and maximum x and y coordinates of
---the subgraph, and returns true if the point is within those bounds, or
---false otherwise.
---@param subgraph dotfiles.mermaid.graph_renderer.LayoutSubgraph the subgraph to check against
---@param point dotfiles.mermaid.graph_renderer.DrawingCoord the point to check for containment within the subgraph's bounding box
---@return boolean point_inside true if the point is inside the subgraph's bounding box, false otherwise
local function point_inside_subgraph(subgraph, point)
  return point.x >= subgraph.min_x
    and point.x <= subgraph.max_x
    and point.y >= subgraph.min_y
    and point.y <= subgraph.max_y
end

---Calculate the attachment point for a subgraph, based on its bounding box
---and the specified direction. The attachment point is the point on the
---subgraph's boundary where an edge should connect, taking into account the
---subgraph's minimum and maximum x and y coordinates and any offsets applied
---to the graph.
---@param subgraph dotfiles.mermaid.graph_renderer.LayoutSubgraph the subgraph for which to calculate the attachment point
---@param direction dotfiles.mermaid.graph_renderer.Direction the direction in which the attachment point should be calculated (e.g., "up", "down", "left", "right")
---@return dotfiles.mermaid.graph_renderer.DrawingCoord drawing_coord the calculated attachment point on the subgraph's boundary, based on its bounding box and the specified direction
local function subgraph_attachment_point(subgraph, direction)
  local center_x = subgraph.min_x + math.floor((subgraph.max_x - subgraph.min_x) / 2)
  local center_y = subgraph.min_y + math.floor((subgraph.max_y - subgraph.min_y) / 2)

  if geometry.same_direction(direction, geometry.Directions.up) then
    return { x = center_x, y = subgraph.min_y }
  end
  if geometry.same_direction(direction, geometry.Directions.down) then
    return { x = center_x, y = subgraph.max_y }
  end
  if geometry.same_direction(direction, geometry.Directions.left) then
    return { x = subgraph.min_x, y = center_y }
  end
  if geometry.same_direction(direction, geometry.Directions.right) then
    return { x = subgraph.max_x, y = center_y }
  end
  if geometry.same_direction(direction, geometry.Directions.upper_left) then
    return { x = subgraph.min_x, y = subgraph.min_y }
  end
  if geometry.same_direction(direction, geometry.Directions.upper_right) then
    return { x = subgraph.max_x, y = subgraph.min_y }
  end
  if geometry.same_direction(direction, geometry.Directions.lower_left) then
    return { x = subgraph.min_x, y = subgraph.max_y }
  end
  if geometry.same_direction(direction, geometry.Directions.lower_right) then
    return { x = subgraph.max_x, y = subgraph.max_y }
  end

  return { x = center_x, y = center_y }
end

---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph
---@param subgraph dotfiles.mermaid.graph_renderer.LayoutSubgraph
---@param direction dotfiles.mermaid.graph_renderer.Direction
---@param node dotfiles.mermaid.graph_renderer.LayoutNode
---@return dotfiles.mermaid.graph_renderer.DrawingCoord
local function aligned_subgraph_attachment_point(graph, subgraph, direction, node)
  local attachment = subgraph_attachment_point(subgraph, direction)

  if geometry.same_direction(direction, geometry.Directions.left)
    or geometry.same_direction(direction, geometry.Directions.right)
  then
    local node_attachment = node_attachment_point(graph, node, direction)
    attachment.y = node_attachment.y
  end

  return attachment
end

---Prepare the edge attachments for subgraphs in the graph, ensuring that
---edges connect to the appropriate attachment points on subgraphs rather than
---their child nodes.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the edges and subgraphs to prepare
local function prepare_subgraph_edge_attachments(graph)
  for _, edge in ipairs(graph.edges) do
    local draw_path = {}
    for index, coord in ipairs(edge.path) do
      draw_path[index] = coord
    end

    local first_index = 1
    local last_index = #draw_path
    local source_subgraph = edge.source_composite_id and graph.subgraph_by_id[edge.source_composite_id] or nil
    local target_subgraph = edge.target_composite_id and graph.subgraph_by_id[edge.target_composite_id] or nil

    if source_subgraph then
      edge.start_attachment_override = aligned_subgraph_attachment_point(graph, source_subgraph, edge.start_dir, edge.from)
      if geometry.same_direction(edge.start_dir, geometry.Directions.down) then
        edge.start_attachment_override.y = edge.start_attachment_override.y - 1
      elseif geometry.same_direction(edge.start_dir, geometry.Directions.up) then
        edge.start_attachment_override.y = edge.start_attachment_override.y + 1
      end

      while
        first_index <= last_index
        and point_inside_subgraph(source_subgraph, grid_to_drawing_coord(graph, draw_path[first_index]))
      do
        first_index = first_index + 1
      end
    else
      edge.start_attachment_override = nil
    end

    if target_subgraph then
      edge.end_attachment_override = aligned_subgraph_attachment_point(graph, target_subgraph, edge.end_dir, edge.to)
      while
        last_index >= first_index
        and point_inside_subgraph(target_subgraph, grid_to_drawing_coord(graph, draw_path[last_index]))
      do
        last_index = last_index - 1
      end
    else
      edge.end_attachment_override = nil
    end

    if first_index > last_index or (last_index - first_index + 1) < 2 then
      edge.draw_path = edge.path
    else
      edge.draw_path = {}
      for index = first_index, last_index do
        edge.draw_path[#edge.draw_path + 1] = draw_path[index]
      end
    end
  end
end

---Measure the dimensions of a state note based on its text content.
---@param note dotfiles.mermaid.graph_renderer.LayoutNote the state note to measure
local function measure_state_note(note)
  local note_lines = text.split_lines(note.text)
  local note_width = 4
  for _, note_line in ipairs(note_lines) do
    note_width = math.max(note_width, text.char_len(note_line) + 4)
  end
  local note_height = #note_lines + 2
  note.width = note_width
  note.height = note_height
end

---Resolve the offset for a state note based on its associated node's drawing
---coordinates and the note's position (left or right). This function
---calculates the x and y coordinates for the note's placement, ensuring that
---it is positioned correctly relative to its associated node.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the nodes and notes
---@param note dotfiles.mermaid.graph_renderer.LayoutNote the state note for which to resolve the offset
---@return dotfiles.mermaid.graph_renderer.DrawingCoord drawing_coord the calculated drawing coordinates for the state note's placement, based on its associated node's drawing coordinates and the note's position
local function resolve_state_note_offset(graph, note)
  local node_size = node_render_size(graph, note.node)
  local node_coord = assert(note.node.drawing_coord, "notes require drawing coordinates")
  local note_width = assert(note.width, "notes must be measured before placement")
  local note_height = assert(note.height, "notes must be measured before placement")
  local note_x = node_coord.x + node_size.width + 4

  if note.position == "left" then
    note_x = math.max(0, node_coord.x - note_width - 4)
  end

  return {
    x = note_x,
    y = math.max(0, node_coord.y - note_height - 6),
  }
end

---Apply a margin to the graph drawing to accommodate state notes, ensuring
---that they do not overlap with the graph's nodes or edges. This function
---measures each state note, calculates the necessary offsets, and adjusts
---the graph's drawing coordinates accordingly.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the nodes and state notes to apply margins for
local function apply_state_note_margin(graph)
  local top_padding = 0

  for _, note in ipairs(graph.notes) do
    measure_state_note(note)
    local node_coord = assert(note.node.drawing_coord, "notes require drawing coordinates")
    local desired_y = node_coord.y - assert(note.height) - 6
    if desired_y < 0 then
      top_padding = math.max(top_padding, -desired_y + 2)
    end
  end

  offset_graph_drawing(graph, 0, top_padding)

  for _, note in ipairs(graph.notes) do
    note.offset = resolve_state_note_offset(graph, note)
  end
end

---Get the origin point for a branch label on an edge, based on the edge's
---drawing path and the direction of the edge. This function calculates the
---appropriate x and y coordinates for the label's placement, ensuring that
---it is positioned correctly relative to the edge's path and any branch
---turns in the edge's route.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the edge and its drawing path
---@param edge dotfiles.mermaid.graph_renderer.LayoutEdge the edge for which to calculate the branch label origin
---@return dotfiles.mermaid.graph_renderer.DrawingCoord drawing_coord the calculated drawing coordinates for the branch label's origin, based on the edge's drawing path and direction
local function get_branch_label_origin(graph, edge)
  local path = edge.path
  if edge.draw_path and #edge.draw_path >= 3 then
    path = edge.draw_path
  end
  local label_width = text.char_len(edge.text)

  if (edge.start_dir == geometry.Directions.left or edge.start_dir == geometry.Directions.right) and #path >= 3 then
    local branch_turn = grid_to_drawing_coord(graph, path[2])
    local label_y = branch_turn.y + 1
    if graph.config and graph.config.graph_direction == "TD" then
      label_y = math.max(0, branch_turn.y - 1)
    end
    return {
      x = math.max(0, branch_turn.x - math.floor(label_width / 2)),
      y = label_y,
    }
  end

  if (edge.start_dir == geometry.Directions.up or edge.start_dir == geometry.Directions.down) and #path >= 3 then
    local branch_turn = grid_to_drawing_coord(graph, path[2])
    return {
      x = branch_turn.x + 2,
      y = math.max(0, branch_turn.y - 1),
    }
  end

  local anchor = edge.start_attachment_override or node_attachment_point(graph, edge.from, edge.start_dir)

  if edge.start_dir == geometry.Directions.left then
    return { x = math.max(0, anchor.x - label_width - 2), y = anchor.y + 1 }
  end
  if edge.start_dir == geometry.Directions.right then
    return { x = anchor.x + 2, y = anchor.y + 1 }
  end
  if edge.start_dir == geometry.Directions.up then
    return { x = anchor.x + 2, y = math.max(0, anchor.y - 1) }
  end
  return { x = anchor.x + 2, y = anchor.y + 1 }
end

---Calculate the maximum x and y coordinates of the entire graph, based on the
---drawing coordinates of all nodes, subgraphs, edges, and notes.
---@param graph dotfiles.mermaid.graph_renderer.LayoutGraph the working layout graph containing the nodes, subgraphs, edges, and notes to calculate the canvas bounds for
local function calculate_canvas_bounds(graph)
  local max_x = 0
  local max_y = 0

  local function include_point(x, y)
    max_x = math.max(max_x, x)
    max_y = math.max(max_y, y)
  end

  for _, node in ipairs(graph.nodes) do
    local node_coord = node.drawing_coord
    if node_coord then
      local rendered_size = node_render_size(graph, node)
      include_point(node_coord.x + rendered_size.width - 1, node_coord.y + rendered_size.height - 1)
    end
  end

  for _, subgraph in ipairs(graph.subgraphs) do
    include_point(subgraph.max_x, subgraph.max_y)
  end

  for _, edge in ipairs(graph.edges) do
    for _, coord in ipairs(edge.draw_path or edge.path) do
      local drawing_coord = grid_to_drawing_coord(graph, coord)
      include_point(drawing_coord.x, drawing_coord.y)
    end
    if edge.start_attachment_override then
      include_point(edge.start_attachment_override.x, edge.start_attachment_override.y)
    end
    if edge.end_attachment_override then
      include_point(edge.end_attachment_override.x, edge.end_attachment_override.y)
    end
    if edge.has_branch_label and edge.text ~= "" then
      local label_origin = get_branch_label_origin(graph, edge)
      include_point(label_origin.x + text.char_len(edge.text), label_origin.y)
    end
  end

  for _, note in ipairs(graph.notes) do
    if note.offset and note.width and note.height then
      include_point(note.offset.x + note.width - 1, note.offset.y + note.height - 1)
    end
  end

  graph.canvas_max_x = max_x
  graph.canvas_max_y = max_y
end

---Prepare the layout of the graph by creating a working layout graph,
---measuring nodes, placing them in the grid, routing edges, assigning drawing
---coordinates, calculating subgraph bounding boxes, applying state note
---margins, preparing subgraph edge attachments, and calculating the overall
---canvas bounds.
---@param normalized dotfiles.mermaid.graph_renderer.NormalizedGraph the normalized graph to prepare for layout
---@return dotfiles.mermaid.graph_renderer.LayoutGraph layout_graph the prepared working layout graph with nodes, edges, subgraphs, and drawing coordinates
local function prepare_layout(normalized)
  local graph = create_working_layout(normalized)
  if #graph.nodes == 0 then
    return graph
  end

  measure_nodes(graph)
  place_nodes(graph)
  routing.prepare_edge_routes(graph)
  assign_drawing_coordinates(graph)
  calculate_subgraph_bounding_boxes(graph)
  offset_drawing_for_subgraphs(graph)
  apply_state_note_margin(graph)
  prepare_subgraph_edge_attachments(graph)
  calculate_canvas_bounds(graph)
  return graph
end

local M = {}
M.prepare_layout = prepare_layout
M.grid_to_drawing_coord = grid_to_drawing_coord
M.node_render_size = node_render_size
M.node_attachment_point = node_attachment_point
M.get_branch_label_origin = get_branch_label_origin
return M
