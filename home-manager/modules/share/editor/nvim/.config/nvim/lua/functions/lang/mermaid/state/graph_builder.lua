---Returns the current container for new members.
---@param subgraph_stack dotfiles.mermaid.Subgraph[]
---@return dotfiles.mermaid.Subgraph|nil
local function get_current_container(subgraph_stack)
  if #subgraph_stack == 0 then
    return nil
  end

  local current_subgraph = subgraph_stack[#subgraph_stack]
  return current_subgraph.active_region or current_subgraph
end

---Adds a node ID to the current subgraph when one is active.
---@param subgraph_stack dotfiles.mermaid.Subgraph[]
---@param node_id string
local function add_node_to_current_subgraph(subgraph_stack, node_id)
  local current_subgraph = get_current_container(subgraph_stack)
  if not current_subgraph then
    return
  end

  current_subgraph.node_ids = current_subgraph.node_ids or {}
  current_subgraph.node_id_set = current_subgraph.node_id_set or {}

  if current_subgraph.node_id_set[node_id] then
    return
  end

  for _, existing_node_id in ipairs(current_subgraph.node_ids) do
    if existing_node_id == node_id then
      current_subgraph.node_id_set[node_id] = true
      return
    end
  end

  current_subgraph.node_ids[#current_subgraph.node_ids + 1] = node_id
  current_subgraph.node_id_set[node_id] = true
end

---Adds a child subgraph to the current container.
---@param subgraph_stack dotfiles.mermaid.Subgraph[]
---@param child_subgraph dotfiles.mermaid.Subgraph
local function add_child_to_current_subgraph(subgraph_stack, child_subgraph)
  local current_subgraph = get_current_container(subgraph_stack)
  if not current_subgraph then
    return
  end

  current_subgraph.children = current_subgraph.children or {}
  current_subgraph.children[#current_subgraph.children + 1] = child_subgraph
end

---Removes a node from the graph and every matching node-order entry.
---@param graph dotfiles.mermaid.state.Graph
---@param node_id string
local function remove_node_by_id(graph, node_id)
  if not graph.nodes[node_id] then
    return
  end

  graph.nodes[node_id] = nil

  for index = #graph.node_order, 1, -1 do
    if graph.node_order[index] == node_id then
      table.remove(graph.node_order, index)
    end
  end
end

---Adds a node to the graph and tracks it in the current subgraph.
---@param graph dotfiles.mermaid.state.Graph
---@param subgraph_stack dotfiles.mermaid.Subgraph[]
---@param node dotfiles.mermaid.Node
local function add_node(graph, subgraph_stack, node)
  if not graph.nodes[node.id] then
    graph.nodes[node.id] = node
    graph.node_order[#graph.node_order + 1] = node.id
  end

  add_node_to_current_subgraph(subgraph_stack, node.id)
end

---Ensures a node exists in the graph and tracks it in the current subgraph.
---@param graph dotfiles.mermaid.state.Graph
---@param subgraph_stack dotfiles.mermaid.Subgraph[]
---@param node_id string
local function ensure_node(graph, subgraph_stack, node_id)
  if not graph.nodes[node_id] then
    add_node(graph, subgraph_stack, {
      id = node_id,
      label = node_id,
      shape = "rounded",
    })
    return
  end

  add_node_to_current_subgraph(subgraph_stack, node_id)
end

local M = {}
M.get_current_container = get_current_container
M.add_node_to_current_subgraph = add_node_to_current_subgraph
M.add_child_to_current_subgraph = add_child_to_current_subgraph
M.remove_node_by_id = remove_node_by_id
M.add_node = add_node
M.ensure_node = ensure_node
return M
