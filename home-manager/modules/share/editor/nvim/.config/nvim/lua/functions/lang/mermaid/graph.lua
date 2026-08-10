---Checks if a list contains a specific value.
---@param list any[] a list of values to search through
---@param wanted any the value to search for in the list
---@return boolean true if the list contains the wanted value, false otherwise
local function has_value(list, wanted)
  for _, value in ipairs(list) do
    if value == wanted then
      return true
    end
  end
  return false
end

---Tracks a node ID in the current subgraph if there is one.
---@param subgraph_stack table[] a stack of subgraph tables
---@param node_id string the ID of the node to track
local function track_in_subgraph(subgraph_stack, node_id)
  if #subgraph_stack == 0 then
    return
  end

  local current = subgraph_stack[#subgraph_stack]
  if not has_value(current.node_ids, node_id) then
    current.node_ids[#current.node_ids + 1] = node_id
  end
end

---Removes a node from the graph and its order list.
---@param graph table the graph table containing nodes and node_order
---@param node_id string the ID of the node to remove
local function remove_node(graph, node_id)
  if not graph.nodes[node_id] then
    return
  end

  graph.nodes[node_id] = nil
  for index = #graph.node_order, 1, -1 do
    if graph.node_order[index] == node_id then
      table.remove(graph.node_order, index)
      break
    end
  end
end

---Registers a state node in the graph and tracks it in the current subgraph
---if applicable.
---@param graph table the graph table containing nodes and node_order
---@param composite_stack table[] a stack of composite state tables
---@param node table the node table to register, containing at least an 'id' field
local function register_state_node(graph, composite_stack, node)
  if not graph.nodes[node.id] then
    graph.nodes[node.id] = node
    graph.node_order[#graph.node_order + 1] = node.id
  end
  track_in_subgraph(composite_stack, node.id)
end

---Ensures that a state node exists in the graph, creating it if necessary,
---and tracks it in the current subgraph if applicable.
---@param graph table the graph table containing nodes and node_order
---@param composite_stack table[] a stack of composite state tables
---@param state_id string the ID of the state node to ensure exists
local function ensure_state_node(graph, composite_stack, state_id)
  if not graph.nodes[state_id] then
    register_state_node(graph, composite_stack, {
      id = state_id,
      label = state_id,
      shape = "rounded",
    })
  elseif #composite_stack > 0 then
    track_in_subgraph(composite_stack, state_id)
  end
end

local M = {}
M.track_in_subgraph = track_in_subgraph
M.remove_node = remove_node
M.register_state_node = register_state_node
M.ensure_state_node = ensure_state_node
return M
