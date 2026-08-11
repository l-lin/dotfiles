---Stage 1: adapt parser output into a renderer-focused graph model.
---
---The parser still exposes diagram-specific details such as composite states that can
---appear as edge endpoints even though they are not concrete drawable nodes. This stage
---resolves those parser quirks once, up front, so later stages can reason in terms of a
---small, shared set of renderer structures.

---Normalize the direction of a subgraph based on the parsed direction.
---@param parsed_direction string|nil the parsed direction of the subgraph, which can be "LR", "RL", "TD", or nil
---@return dotfiles.mermaid.graph_renderer.GraphDirection|nil graph_direction the normalized direction of the subgraph, which will be "LR" for left-to-right or "TD" for top-to-bottom, or nil if the parsed direction is nil
local function normalize_subgraph_direction(parsed_direction)
  if not parsed_direction then
    return nil
  end

  if parsed_direction == "LR" or parsed_direction == "RL" then
    return "LR"
  end

  return "TD"
end

---Normalize the direction of the graph based on the parsed direction.
---@param parsed_direction string|nil the parsed direction of the graph, which can be "LR", "RL", "TD", or nil
---@return dotfiles.mermaid.graph_renderer.GraphDirection graph_direction the normalized direction of the graph, which will be "LR" for left-to-right or "TD" for top-to-bottom, defaulting to "TD" if the parsed direction is nil
local function normalize_graph_direction(parsed_direction)
  if parsed_direction == "LR" or parsed_direction == "RL" then
    return "LR"
  end

  return "TD"
end

---Convert a parsed subgraph into a normalized subgraph for rendering, recursively processing its children and nodes.
---@param parsed_subgraph dotfiles.mermaid.Subgraph the parsed subgraph to convert
---@param parent dotfiles.mermaid.graph_renderer.NormalizedSubgraph|nil the parent normalized subgraph, or nil if this is a top-level subgraph
---@param node_by_id table<string, dotfiles.mermaid.graph_renderer.NormalizedNode> the mapping of node IDs to normalized nodes for quick lookup
---@param all_subgraphs dotfiles.mermaid.graph_renderer.NormalizedSubgraph[] the list of all normalized subgraphs, which will be populated during the conversion process
---@param converted_by_parsed table<dotfiles.mermaid.Subgraph, dotfiles.mermaid.graph_renderer.NormalizedSubgraph> the mapping of parsed subgraphs to their corresponding normalized subgraphs
---@return dotfiles.mermaid.graph_renderer.NormalizedSubgraph normalized_subgraph the converted normalized subgraph
local function convert_subgraph(parsed_subgraph, parent, node_by_id, all_subgraphs, converted_by_parsed)
  ---@type dotfiles.mermaid.graph_renderer.NormalizedSubgraph
  local subgraph = {
    id = parsed_subgraph.id,
    name = parsed_subgraph.label,
    kind = parsed_subgraph.kind,
    nodes = {},
    parent = parent,
    children = {},
    direction = normalize_subgraph_direction(parsed_subgraph.direction),
    depth = parent and (parent.depth + 1) or 0,
  }

  converted_by_parsed[parsed_subgraph] = subgraph

  for _, node_id in ipairs(parsed_subgraph.node_ids) do
    local node = node_by_id[node_id]
    if node then
      subgraph.nodes[#subgraph.nodes + 1] = node
    end
  end

  all_subgraphs[#all_subgraphs + 1] = subgraph

  for _, child_parsed_subgraph in ipairs(parsed_subgraph.children) do
    local child = convert_subgraph(child_parsed_subgraph, subgraph, node_by_id, all_subgraphs, converted_by_parsed)
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

---@param candidate dotfiles.mermaid.graph_renderer.NormalizedSubgraph|dotfiles.mermaid.graph_renderer.LayoutSubgraph
---@param target dotfiles.mermaid.graph_renderer.NormalizedSubgraph|dotfiles.mermaid.graph_renderer.LayoutSubgraph
---@return boolean
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

---@param parsed_subgraph dotfiles.mermaid.Subgraph
---@param converted_by_parsed table<dotfiles.mermaid.Subgraph, dotfiles.mermaid.graph_renderer.NormalizedSubgraph>
---@param node_owner table<string, dotfiles.mermaid.graph_renderer.NormalizedSubgraph>
local function claim_leaf_node_owners(parsed_subgraph, converted_by_parsed, node_owner)
  local renderer_subgraph = converted_by_parsed[parsed_subgraph]
  if not renderer_subgraph then
    return
  end

  for _, child in ipairs(parsed_subgraph.children) do
    claim_leaf_node_owners(child, converted_by_parsed, node_owner)
  end

  for _, node_id in ipairs(parsed_subgraph.node_ids) do
    if not node_owner[node_id] then
      node_owner[node_id] = renderer_subgraph
    end
  end
end

---Deduplicate nodes in renderer subgraphs based on ownership determined from parsed subgraphs.
---@param parsed_subgraphs dotfiles.mermaid.Subgraph[] the parsed subgraphs from the Mermaid parser
---@param renderer_subgraphs dotfiles.mermaid.graph_renderer.NormalizedSubgraph[] the normalized subgraphs for rendering
---@param converted_by_parsed table<dotfiles.mermaid.Subgraph, dotfiles.mermaid.graph_renderer.NormalizedSubgraph> the mapping of parsed subgraphs to their corresponding normalized subgraphs
local function deduplicate_subgraph_nodes(parsed_subgraphs, renderer_subgraphs, converted_by_parsed)
  local node_owner = {}

  for _, parsed_subgraph in ipairs(parsed_subgraphs) do
    claim_leaf_node_owners(parsed_subgraph, converted_by_parsed, node_owner)
  end

  for _, renderer_subgraph in ipairs(renderer_subgraphs) do
    local deduplicated = {}
    for _, node in ipairs(renderer_subgraph.nodes) do
      local owner = node_owner[node.name]
      if not owner or is_ancestor_or_self(renderer_subgraph, owner) then
        deduplicated[#deduplicated + 1] = node
      end
    end
    renderer_subgraph.nodes = deduplicated
  end
end

---Pick an anchor node ID from a parsed subgraph based on the preferred shape and traversal order.
---@param parsed_subgraph dotfiles.mermaid.Subgraph the parsed subgraph to search for an anchor node
---@param parsed_nodes table<string, dotfiles.mermaid.Node> the mapping of node IDs to parsed nodes for quick lookup
---@param preferred_shape string|nil the preferred shape of the anchor node to find, or nil to accept any shape
---@param reverse boolean true to traverse the subgraph in reverse order, false to traverse in normal order
---@return string|nil node_id the ID of the found anchor node, or nil if no suitable node is found
local function pick_subgraph_anchor_node_id(parsed_subgraph, parsed_nodes, preferred_shape, reverse)
  if reverse then
    for index = #parsed_subgraph.node_ids, 1, -1 do
      local node_id = parsed_subgraph.node_ids[index]
      local parsed_node = parsed_nodes[node_id]
      if parsed_node and parsed_node.shape == preferred_shape then
        return node_id
      end
    end

    for index = #parsed_subgraph.children, 1, -1 do
      local child_node_id =
        pick_subgraph_anchor_node_id(parsed_subgraph.children[index], parsed_nodes, preferred_shape, reverse)
      if child_node_id then
        return child_node_id
      end
    end

    for index = #parsed_subgraph.node_ids, 1, -1 do
      local node_id = parsed_subgraph.node_ids[index]
      if parsed_nodes[node_id] then
        return node_id
      end
    end

    for index = #parsed_subgraph.children, 1, -1 do
      local child_node_id = pick_subgraph_anchor_node_id(parsed_subgraph.children[index], parsed_nodes, nil, reverse)
      if child_node_id then
        return child_node_id
      end
    end

    return nil
  end

  for _, node_id in ipairs(parsed_subgraph.node_ids) do
    local parsed_node = parsed_nodes[node_id]
    if parsed_node and parsed_node.shape == preferred_shape then
      return node_id
    end
  end

  for _, child in ipairs(parsed_subgraph.children) do
    local child_node_id = pick_subgraph_anchor_node_id(child, parsed_nodes, preferred_shape, reverse)
    if child_node_id then
      return child_node_id
    end
  end

  for _, node_id in ipairs(parsed_subgraph.node_ids) do
    if parsed_nodes[node_id] then
      return node_id
    end
  end

  for _, child in ipairs(parsed_subgraph.children) do
    local child_node_id = pick_subgraph_anchor_node_id(child, parsed_nodes, nil, reverse)
    if child_node_id then
      return child_node_id
    end
  end

  return nil
end

---@class dotfiles.mermaid.graph_renderer.CompositeAnchor
---@field entry_node_id string|nil the ID of the entry node for the composite state, or nil if no suitable entry node is found
---@field exit_node_id string|nil the ID of the exit node for the composite state, or nil if no suitable exit node is found

---Build a mapping of composite state IDs to their corresponding entry and exit node IDs for anchor resolution.
---@param parsed_subgraphs dotfiles.mermaid.Subgraph[] the parsed subgraphs from the Mermaid parser
---@param parsed_nodes table<string, dotfiles.mermaid.Node> the mapping of node IDs to parsed nodes for quick lookup
---@param result table<string, dotfiles.mermaid.graph_renderer.CompositeAnchor>|nil the result table to populate with composite anchor mappings, or nil to create a new table
---@return table<string, dotfiles.mermaid.graph_renderer.CompositeAnchor> result the populated mapping of composite state IDs to their corresponding entry and exit node IDs
local function build_subgraph_anchor_map(parsed_subgraphs, parsed_nodes, result)
  result = result or {}

  for _, parsed_subgraph in ipairs(parsed_subgraphs) do
    result[parsed_subgraph.id] = {
      entry_node_id = pick_subgraph_anchor_node_id(parsed_subgraph, parsed_nodes, "state-start", false),
      exit_node_id = pick_subgraph_anchor_node_id(parsed_subgraph, parsed_nodes, "state-end", true),
    }
    build_subgraph_anchor_map(parsed_subgraph.children, parsed_nodes, result)
  end

  return result
end

---Build an index mapping each node to its innermost containing subgraph for quick lookup during rendering.
---@param subgraphs dotfiles.mermaid.graph_renderer.NormalizedSubgraph[] the list of normalized subgraphs for rendering
---@return table<dotfiles.mermaid.graph_renderer.NormalizedNode, dotfiles.mermaid.graph_renderer.NormalizedSubgraph> index the mapping of each node to its innermost containing subgraph
local function build_innermost_subgraph_index(subgraphs)
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

---Process the parsed graph data from the Mermaid parser into a normalized graph structure suitable for rendering.
---@param parsed dotfiles.mermaid.graph_renderer.ParsedGraph the parsed graph data from the Mermaid parser
---@return dotfiles.mermaid.graph_renderer.NormalizedGraph normalized_graph normalized graph structure suitable for rendering
local function from_parsed(parsed)
  ---@type table<string, dotfiles.mermaid.graph_renderer.NormalizedNode>
  local node_by_id = {}
  ---@type dotfiles.mermaid.graph_renderer.NormalizedNode[]
  local nodes = {}

  for _, node_id in ipairs(parsed.node_order) do
    local parsed_node = parsed.nodes[node_id]
    if parsed_node then
      ---@type dotfiles.mermaid.graph_renderer.NormalizedNode
      local node = {
        name = node_id,
        display_label = parsed_node.label,
        shape = parsed_node.shape,
        index = #nodes + 1,
      }
      node_by_id[node_id] = node
      nodes[#nodes + 1] = node
    end
  end

  local composite_anchor_by_id = build_subgraph_anchor_map(parsed.subgraphs, parsed.nodes)

  ---@type dotfiles.mermaid.graph_renderer.NormalizedEdge[]
  local edges = {}
  for _, parsed_edge in ipairs(parsed.edges) do
    local resolved_source_id = parsed_edge.source
    local resolved_target_id = parsed_edge.target
    local source_anchor = composite_anchor_by_id[resolved_source_id]
    local target_anchor = composite_anchor_by_id[resolved_target_id]

    if not node_by_id[resolved_source_id] and source_anchor and source_anchor.exit_node_id then
      resolved_source_id = source_anchor.exit_node_id
    end
    if not node_by_id[resolved_target_id] and target_anchor and target_anchor.entry_node_id then
      resolved_target_id = target_anchor.entry_node_id
    end

    local from = node_by_id[resolved_source_id]
    local to = node_by_id[resolved_target_id]
    if from and to then
      edges[#edges + 1] = {
        from = from,
        to = to,
        text = parsed_edge.label or "",
        style = parsed_edge.style or "solid",
        has_arrow_start = parsed_edge.has_arrow_start,
        has_arrow_end = parsed_edge.has_arrow_end,
        source_composite_id = source_anchor and parsed_edge.source or nil,
        target_composite_id = target_anchor and parsed_edge.target or nil,
      }
    end
  end

  ---@type dotfiles.mermaid.graph_renderer.NormalizedNote[]
  local notes = {}
  for _, parsed_note in ipairs(parsed.notes or {}) do
    local anchor_node = node_by_id[parsed_note.state_id]
    if anchor_node then
      notes[#notes + 1] = {
        node = anchor_node,
        position = parsed_note.position,
        text = parsed_note.text,
      }
    end
  end

  ---@type dotfiles.mermaid.graph_renderer.NormalizedSubgraph[]
  local subgraphs = {}
  ---@type table<dotfiles.mermaid.Subgraph, dotfiles.mermaid.graph_renderer.NormalizedSubgraph>
  local converted_by_parsed = {}

  for _, parsed_subgraph in ipairs(parsed.subgraphs) do
    convert_subgraph(parsed_subgraph, nil, node_by_id, subgraphs, converted_by_parsed)
  end

  deduplicate_subgraph_nodes(parsed.subgraphs, subgraphs, converted_by_parsed)

  ---@type table<string, dotfiles.mermaid.graph_renderer.NormalizedSubgraph>
  local subgraph_by_id = {}
  for _, subgraph in ipairs(subgraphs) do
    subgraph_by_id[subgraph.id] = subgraph
  end

  return {
    nodes = nodes,
    edges = edges,
    subgraphs = subgraphs,
    subgraph_by_id = subgraph_by_id,
    innermost_subgraph_by_node = build_innermost_subgraph_index(subgraphs),
    notes = notes,
    config = {
      padding_x = 5,
      padding_y = 5,
      box_border_padding = 1,
      graph_direction = normalize_graph_direction(parsed.direction),
    },
    parsed_direction = parsed.direction,
  }
end

local M = {}
M.from_parsed = from_parsed
M.is_ancestor_or_self = is_ancestor_or_self
return M
