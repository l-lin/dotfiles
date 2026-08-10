local parser = require("functions.lang.mermaid.parser")
local text = require("functions.lang.mermaid.text")

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

---Parses a list of lines representing a Mermaid state diagram and constructs
---a graph representation.
---@param lines string[] a list of lines from the Mermaid state diagram
---@return dotfiles.mermaid.state.Graph|nil a graph representation containing nodes, edges, subgraphs, and other properties
---@return string|nil an error message if the input is invalid, or nil if parsing was successful
local function parse(lines)
  if #lines < 1 or not lines[1]:match("^stateDiagram%-v2%s*$") then
    return nil, "Invalid state diagram: missing 'stateDiagram-v2' header"
  end

  ---@type dotfiles.mermaid.state.Graph
  local graph = {
    direction = "TD",
    nodes = {},
    node_order = {},
    edges = {},
    subgraphs = {},
    class_defs = {},
    class_assignments = {},
    node_styles = {},
    link_styles = {},
    warnings = {},
  }

  local composite_stack = {}
  local composite_state_ids = {}
  local start_count = 0
  local end_count = 0

  for index = 2, #lines do
    local line = lines[index]

    local inline_direction = line:match("^direction%s+(%S+)%s*$")

    if inline_direction then
      local normalized_inline_direction = inline_direction:upper()
      if ({ TD = true, TB = true, LR = true, BT = true, RL = true })[normalized_inline_direction] then
        if #composite_stack > 0 then
          composite_stack[#composite_stack].direction = normalized_inline_direction
        else
          graph.direction = normalized_inline_direction
        end
        goto continue
      end
    end

    local link_style_rest = line:match("^linkStyle%s+(.+)$")
    if link_style_rest then
      local target, props = link_style_rest:match("^(.-)%s+([%w%-]+:.*)$")
      if target and props then
        local style_props = parser.parse_style_props(props)
        local normalized_target = parser.trim(target)
        if normalized_target == "default" then
          graph.link_styles.default = graph.link_styles.default or {}
          for key, value in pairs(style_props) do
            graph.link_styles.default[key] = value
          end
        else
          for raw_index in normalized_target:gmatch("[^,%s]+") do
            local numeric_index = tonumber(raw_index)
            if numeric_index ~= nil then
              graph.link_styles[numeric_index] = graph.link_styles[numeric_index] or {}
              for key, value in pairs(style_props) do
                graph.link_styles[numeric_index][key] = value
              end
            end
          end
        end
        goto continue
      end
    end

    local aliased_composite_label, aliased_composite_id = line:match('^state%s+"([^"]+)"%s+as%s+([^%s{]+)%s*{$')
    local composite_id = aliased_composite_id
    local composite_label = aliased_composite_label
    if not composite_id then
      composite_id = line:match("^state%s+([^%s{]+)%s*{$")
      composite_label = composite_id
    end

    if composite_id then
      composite_stack[#composite_stack + 1] = {
        id = composite_id,
        label = text.normalize_br_tags(composite_label),
        node_ids = {},
        children = {},
      }
      composite_state_ids[composite_id] = true
      remove_node(graph, composite_id)
      goto continue
    end

    if line == "}" then
      local completed = table.remove(composite_stack)
      if not completed then
        parser.add_warning(graph, line)
      else
        if #composite_stack > 0 then
          composite_stack[#composite_stack].children[#composite_stack[#composite_stack].children + 1] = completed
        else
          graph.subgraphs[#graph.subgraphs + 1] = completed
        end
      end
      goto continue
    end

    local state_alias_label, state_alias_id = line:match('^state%s+"([^"]+)"%s+as%s+([^%s]+)%s*$')
    if state_alias_id then
      register_state_node(graph, composite_stack, {
        id = state_alias_id,
        label = text.normalize_br_tags(state_alias_label),
        shape = "rounded",
      })
      goto continue
    end

    local before_arrow, after_arrow = line:match("^(.-)%-%->%s*(.+)$")
    if before_arrow and after_arrow then
      local source_id = parser.trim(before_arrow)
      local target_segment = parser.trim(after_arrow)
      local target_id = target_segment
      local raw_label = nil

      local matched_target_id, matched_label = target_segment:match("^(.-)%s*:%s*(.+)$")
      if matched_target_id and matched_label then
        target_id = parser.trim(matched_target_id)
        raw_label = parser.trim(matched_label)
      end

      if source_id ~= "" and target_id ~= "" then
        local normalized_source = source_id
        local normalized_target = target_id

        if normalized_source == "[*]" then
          start_count = start_count + 1
          normalized_source = start_count == 1 and "_start" or ("_start" .. start_count)
          register_state_node(graph, composite_stack, {
            id = normalized_source,
            label = "",
            shape = "state-start",
          })
        elseif not composite_state_ids[normalized_source] then
          ensure_state_node(graph, composite_stack, normalized_source)
        end

        if normalized_target == "[*]" then
          end_count = end_count + 1
          normalized_target = end_count == 1 and "_end" or ("_end" .. end_count)
          register_state_node(graph, composite_stack, {
            id = normalized_target,
            label = "",
            shape = "state-end",
          })
        elseif not composite_state_ids[normalized_target] then
          ensure_state_node(graph, composite_stack, normalized_target)
        end

        graph.edges[#graph.edges + 1] = {
          source = normalized_source,
          target = normalized_target,
          label = raw_label and text.normalize_br_tags(raw_label) or nil,
          style = "solid",
          has_arrow_start = false,
          has_arrow_end = true,
        }
        goto continue
      end
    end

    local described_state_id, described_state_label = line:match("^([^%s:]+)%s*:%s*(.+)$")
    if described_state_id and described_state_label then
      register_state_node(graph, composite_stack, {
        id = described_state_id,
        label = text.normalize_br_tags(parser.trim(described_state_label)),
        shape = "rounded",
      })
      goto continue
    end

    parser.add_warning(graph, line)

    ::continue::
  end

  if #composite_stack > 0 then
    parser.add_warning(graph, "unterminated state block")
  end

  return graph
end

local M = {}
M.parse = parse
return M
