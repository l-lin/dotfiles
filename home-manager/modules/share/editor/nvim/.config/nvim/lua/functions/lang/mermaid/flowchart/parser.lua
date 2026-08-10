local parser = require("functions.lang.mermaid.parser")
local text = require("functions.lang.mermaid.text")
local graph_helpers = require("functions.lang.mermaid.graph")

local NODE_PATTERNS = {
  { pattern = "^([%w_%-]+)%(%(%((.-)%)%)%)", shape = "doublecircle" },
  { pattern = "^([%w_%-]+)%(%[(.-)%]%)", shape = "stadium" },
  { pattern = "^([%w_%-]+)%(%((.-)%)%)", shape = "circle" },
  { pattern = "^([%w_%-]+)%[%[(.-)%]%]", shape = "subroutine" },
  { pattern = "^([%w_%-]+)%[%((.-)%)%]", shape = "cylinder" },
  { pattern = "^([%w_%-]+)%[/(.-)\\%]", shape = "trapezoid" },
  { pattern = "^([%w_%-]+)%[\\(.-)/%]", shape = "trapezoid-alt" },
  { pattern = "^([%w_%-]+)>(.-)%]", shape = "asymmetric" },
  { pattern = "^([%w_%-]+){{(.-)}}", shape = "hexagon" },
  { pattern = "^([%w_%-]+)%[(.-)%]", shape = "rectangle" },
  { pattern = "^([%w_%-]+)%((.-)%)", shape = "rounded" },
  { pattern = "^([%w_%-]+){(.-)}", shape = "diamond" },
}

local EDGE_OPERATORS = {
  "-.->",
  "-->",
  "==>",
  "-.-",
  "---",
  "===",
}

local TEXT_ARROW_OPENERS = {
  "--",
  "-.",
  "==",
}

local TEXT_ARROW_CLOSERS = {
  "-->",
  "---",
  ".->",
  "-.-",
  "==>",
  "===",
}

---Registers a node in the graph and tracks it in the current subgraph stack.
---@param graph table The graph object to register the node in.
---@param subgraph_stack table The stack of subgraphs to track the node in.
---@param node table The node object to register, containing 'id', 'label', and '
local function register_node(graph, subgraph_stack, node)
  if not graph.nodes[node.id] then
    graph.nodes[node.id] = node
    graph.node_order[#graph.node_order + 1] = node.id
  end
  graph_helpers.track_in_subgraph(subgraph_stack, node.id)
end

---Consumes a node from the given text value, registers it in the graph, and
---returns the node's identifier and remaining text.
---@param text_value string The text value to consume the node from.
---@param graph table The graph object to register the node in.
---@param subgraph_stack table The stack of subgraphs to track the node in.
---@return dotfiles.mermaid.flowchart.ConsumeNodeResult|nil The result containing the node's identifier and remaining text, or nil if no node was consumed.
local function consume_node(text_value, graph, subgraph_stack)
  local identifier = nil
  local remaining = text_value

  for _, candidate in ipairs(NODE_PATTERNS) do
    local full_start, full_end, matched_id, raw_label = text_value:find(candidate.pattern)
    if full_start == 1 and matched_id then
      identifier = matched_id
      register_node(graph, subgraph_stack, {
        id = matched_id,
        label = text.normalize_br_tags(raw_label),
        shape = candidate.shape,
      })
      remaining = text_value:sub(full_end + 1)
      break
    end
  end

  if not identifier then
    local bare_identifier = text_value:match("^([%w_%-]+)")
    if bare_identifier then
      identifier = bare_identifier
      if not graph.nodes[bare_identifier] then
        register_node(graph, subgraph_stack, {
          id = bare_identifier,
          label = bare_identifier,
          shape = "rectangle",
        })
      end
      remaining = text_value:sub(#bare_identifier + 1)
    end
  end

  if not identifier then
    return nil
  end

  local class_name = remaining:match("^:::([%w][%w%-]*)")
  if class_name then
    graph.class_assignments[identifier] = class_name
    remaining = remaining:sub(#class_name + 4)
  end

  return {
    id = identifier,
    remaining = remaining,
  }
end

---Consumes a group of nodes from the given text value, registers them in the
---graph, and returns their identifiers and remaining text.
---@param text_value string The text value to consume the node group from.
---@param graph table The graph object to register the nodes in.
---@param subgraph_stack table The stack of subgraphs to track the nodes in.
---@return dotfiles.mermaid.flowchart.ConsumeNodeGroupResult|nil The result containing the node identifiers and remaining text, or nil if no nodes were consumed.
local function consume_node_group(text_value, graph, subgraph_stack)
  local first = consume_node(text.trim(text_value), graph, subgraph_stack)
  if not first then
    return nil
  end

  local identifiers = { first.id }
  local remaining = text.trim(first.remaining)

  while remaining:sub(1, 1) == "&" do
    local next_node = consume_node(text.trim(remaining:sub(2)), graph, subgraph_stack)
    if not next_node then
      break
    end
    identifiers[#identifiers + 1] = next_node.id
    remaining = text.trim(next_node.remaining)
  end

  return {
    ids = identifiers,
    remaining = remaining,
  }
end

---Determines the style of an arrow based on its operator.
---@param operator string The operator representing the arrow.
---@return string The style of the arrow ("dotted", "thick", or "solid").
local function arrow_style_from_op(operator)
  if operator == "-.->" or operator == "-.-" or operator == ".->" then
    return "dotted"
  end
  if operator == "==>" or operator == "===" then
    return "thick"
  end
  return "solid"
end

---Determines the style of a text arrow based on its open and close operators.
---@param open_operator string The open operator representing the start of the text arrow.
---@param close_operator string The close operator representing the end of the text arrow.
---@return string The style of the text arrow ("dotted", "thick", or "solid").
local function text_arrow_style_from_ops(open_operator, close_operator)
  if open_operator == "-." or close_operator == ".->" or close_operator == "-.-" then
    return "dotted"
  end
  if open_operator == "==" or close_operator == "==>" or close_operator == "===" then
    return "thick"
  end
  return "solid"
end

---Consumes an arrow from the given text value, extracting its label, style,
---and remaining text.
---@param text_value string The text value to consume the arrow from.
---@return dotfiles.mermaid.flowchart.ConsumeArrowResult|nil A table containing the arrow's label, style, arrow start/end flags
local function consume_arrow(text_value)
  local remaining = text.trim(text_value)
  local has_arrow_start = false

  if remaining:sub(1, 1) == "<" then
    has_arrow_start = true
    remaining = remaining:sub(2)
  end

  for _, operator in ipairs(EDGE_OPERATORS) do
    if remaining:sub(1, #operator) == operator then
      local rest = remaining:sub(#operator + 1)
      local edge_label = nil

      if rest:sub(1, 1) == "|" then
        local label_end = rest:find("|", 2, true)
        if not label_end then
          return nil
        end
        local raw_label = text.trim(rest:sub(2, label_end - 1))
        if raw_label ~= "" then
          edge_label = text.normalize_br_tags(raw_label)
        end
        rest = rest:sub(label_end + 1)
      end

      ---@type dotfiles.mermaid.flowchart.ConsumeArrowResult
      return {
        label = edge_label,
        style = arrow_style_from_op(operator),
        has_arrow_start = has_arrow_start,
        has_arrow_end = operator:sub(-1) == ">",
        remaining = text.trim(rest),
      }
    end
  end

  for _, open_operator in ipairs(TEXT_ARROW_OPENERS) do
    if remaining:sub(1, #open_operator) == open_operator then
      local after_open = remaining:sub(#open_operator + 1)
      if not after_open:match("^%s") then
        return nil
      end

      after_open = text.ltrim(after_open)
      local best_position = nil
      local best_close = nil

      for _, close_operator in ipairs(TEXT_ARROW_CLOSERS) do
        local position = after_open:find(" " .. close_operator, 1, true)
        if position and (not best_position or position < best_position) then
          best_position = position
          best_close = close_operator
        end
      end

      if best_position and best_close then
        local raw_label = text.rtrim(after_open:sub(1, best_position - 1))
        if raw_label == "" then
          return nil
        end

        return {
          label = text.normalize_br_tags(raw_label),
          style = text_arrow_style_from_ops(open_operator, best_close),
          has_arrow_start = has_arrow_start,
          has_arrow_end = best_close:sub(-1) == ">",
          remaining = text.trim(after_open:sub(best_position + 1 + #best_close)),
        }
      end
    end
  end

  return nil
end

---Copies the values from the given array into a new array.
---@param values any[] The array of values to copy.
---@return any[] A new array containing the copied values.
local function array_copy(values)
  local copied = {}
  for index, value in ipairs(values) do
    copied[index] = value
  end
  return copied
end

---Shallow copies the key-value pairs from the given table into a new table.
---@param values table The table of key-value pairs to copy.
---@return table A new table containing the copied key-value pairs.
local function shallow_copy(values)
  local copied = {}
  for key, value in pairs(values) do
    copied[key] = value
  end
  return copied
end

---Parses a line representing edges in the graph, consuming node groups and
---arrows, and adding the corresponding edges to the graph.
---@param line string The line to parse for edges.
---@param graph table The graph object to add edges to.
---@param subgraph_stack table The stack of subgraphs to track nodes in.
---@return boolean True if the line was successfully parsed and edges were added, false otherwise.
local function parse_edge_line(line, graph, subgraph_stack)
  local first_group = consume_node_group(line, graph, subgraph_stack)
  if not first_group or #first_group.ids == 0 then
    return false
  end

  local remaining = text.trim(first_group.remaining)
  local previous_group = first_group.ids
  local parsed_arrow = false

  while remaining ~= "" do
    local arrow = consume_arrow(remaining)
    if not arrow then
      break
    end

    local next_group = consume_node_group(arrow.remaining, graph, subgraph_stack)
    if not next_group or #next_group.ids == 0 then
      return false
    end

    remaining = text.trim(next_group.remaining)

    for _, source_id in ipairs(previous_group) do
      for _, target_id in ipairs(next_group.ids) do
        graph.edges[#graph.edges + 1] = {
          source = source_id,
          target = target_id,
          label = arrow.label,
          style = arrow.style,
          has_arrow_start = arrow.has_arrow_start,
          has_arrow_end = arrow.has_arrow_end,
        }
      end
    end

    previous_group = next_group.ids
    parsed_arrow = true
  end

  if remaining ~= "" then
    return false
  end

  return parsed_arrow or #previous_group > 0
end

local function parse(lines)
  local keyword, direction = lines[1]:match("^(%S+)%s+(%S+)%s*$")
  if not keyword or not direction then
    return nil,
      string.format(
        'Invalid mermaid header: "%s". Expected "graph TD", "flowchart LR", "stateDiagram-v2", etc.',
        lines[1]
      )
  end

  local lowered_keyword = keyword:lower()
  local normalized_direction = direction:upper()
  if lowered_keyword ~= "graph" and lowered_keyword ~= "flowchart" then
    return nil,
      string.format(
        'Invalid mermaid header: "%s". Expected "graph TD", "flowchart LR", "stateDiagram-v2", etc.',
        lines[1]
      )
  end
  if not ({ TD = true, TB = true, LR = true, BT = true, RL = true })[normalized_direction] then
    return nil,
      string.format(
        'Invalid mermaid header: "%s". Expected "graph TD", "flowchart LR", "stateDiagram-v2", etc.',
        lines[1]
      )
  end

  ---@type dotfiles.mermaid.flowchart.Graph
  local graph = {
    direction = normalized_direction,
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

  local subgraph_stack = {}

  for index = 2, #lines do
    local line = lines[index]

    local class_def_name, class_def_props = line:match("^classDef%s+([%w_]+)%s+(.+)$")
    if class_def_name and class_def_props then
      graph.class_defs[class_def_name] = parser.parse_style_props(class_def_props)
      goto continue
    end

    local class_targets, class_name = line:match("^class%s+([%w_,%-]+)%s+([%w_]+)$")
    if class_targets and class_name then
      for node_id in class_targets:gmatch("[^,]+") do
        graph.class_assignments[text.trim(node_id)] = class_name
      end
      goto continue
    end

    local styled_targets, styled_props = line:match("^style%s+([%w_,%-]+)%s+(.+)$")
    if styled_targets and styled_props then
      local props = parser.parse_style_props(styled_props)
      for node_id in styled_targets:gmatch("[^,]+") do
        local normalized_id = text.trim(node_id)
        graph.node_styles[normalized_id] = graph.node_styles[normalized_id] or {}
        for key, value in pairs(props) do
          graph.node_styles[normalized_id][key] = value
        end
      end
      goto continue
    end

    local link_style_rest = line:match("^linkStyle%s+(.+)$")
    if link_style_rest then
      local target, props = link_style_rest:match("^(.-)%s+([%w%-]+:.*)$")
      if target and props then
        local style_props = parser.parse_style_props(props)
        local normalized_target = text.trim(target)
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

    local inline_direction = line:match("^direction%s+(%S+)%s*$")
    if inline_direction and #subgraph_stack > 0 then
      local normalized_inline_direction = inline_direction:upper()
      if ({ TD = true, TB = true, LR = true, BT = true, RL = true })[normalized_inline_direction] then
        subgraph_stack[#subgraph_stack].direction = normalized_inline_direction
        goto continue
      end
    end

    local subgraph_rest = line:match("^subgraph%s+(.+)$")
    if subgraph_rest then
      local subgraph_id = nil
      local subgraph_label = nil
      local bracket_id, bracket_label = subgraph_rest:match("^([%w%-]+)%s*%[(.+)%]$")
      if bracket_id and bracket_label then
        subgraph_id = bracket_id
        subgraph_label = text.normalize_br_tags(bracket_label)
      else
        subgraph_label = text.normalize_br_tags(text.trim(subgraph_rest))
        subgraph_id = text.slugify(subgraph_rest)
      end

      subgraph_stack[#subgraph_stack + 1] = {
        id = subgraph_id,
        label = subgraph_label,
        node_ids = {},
        children = {},
      }
      goto continue
    end

    if line == "end" then
      local completed = table.remove(subgraph_stack)
      if not completed then
        parser.add_warning(graph, line)
      else
        if #subgraph_stack > 0 then
          local parent = subgraph_stack[#subgraph_stack]
          parent.children[#parent.children + 1] = completed
        else
          graph.subgraphs[#graph.subgraphs + 1] = completed
        end
      end
      goto continue
    end

    local snapshot = {
      nodes = shallow_copy(graph.nodes),
      node_order = array_copy(graph.node_order),
      edges = array_copy(graph.edges),
      class_assignments = shallow_copy(graph.class_assignments),
      subgraph_node_ids = {},
    }
    for stack_index, subgraph in ipairs(subgraph_stack) do
      snapshot.subgraph_node_ids[stack_index] = array_copy(subgraph.node_ids)
    end

    if not parse_edge_line(line, graph, subgraph_stack) then
      graph.nodes = snapshot.nodes
      graph.node_order = snapshot.node_order
      graph.edges = snapshot.edges
      graph.class_assignments = snapshot.class_assignments
      for stack_index, subgraph in ipairs(subgraph_stack) do
        subgraph.node_ids = snapshot.subgraph_node_ids[stack_index] or {}
      end
      parser.add_warning(graph, line)
    end

    ::continue::
  end

  if #subgraph_stack > 0 then
    parser.add_warning(graph, "unterminated subgraph")
  end

  return graph
end

local M = {}
M.parse = parse
return M
