local parser = require("functions.lang.mermaid.parser")

local function current_group_path(group_stack)
  if #group_stack == 0 then
    return nil
  end
  return group_stack[#group_stack].path
end

local function format_node(node)
  if node.shape == "round" then
    return "(" .. node.label .. ")"
  end
  if node.shape == "decision" then
    return "{" .. node.label .. "}"
  end
  if node.shape == "terminal" then
    return node.label
  end
  return "[" .. node.label .. "]"
end

local function skip_spaces(text, start_index)
  local index = start_index
  while index <= #text and text:sub(index, index):match("%s") do
    index = index + 1
  end
  return index
end

local function read_shape(text, start_index)
  local two_chars = text:sub(start_index, start_index + 1)
  local one_char = text:sub(start_index, start_index)
  local open_length
  local close_token
  local shape

  if two_chars == "([" then
    open_length = 2
    close_token = "])"
    shape = "round"
  elseif two_chars == "[[" then
    open_length = 2
    close_token = "]]"
    shape = "rect"
  elseif two_chars == "((" then
    open_length = 2
    close_token = "))"
    shape = "round"
  elseif one_char == "[" then
    open_length = 1
    close_token = "]"
    shape = "rect"
  elseif one_char == "(" then
    open_length = 1
    close_token = ")"
    shape = "round"
  elseif one_char == "{" then
    open_length = 1
    close_token = "}"
    shape = "decision"
  else
    return nil, nil, start_index
  end

  local label_start = start_index + open_length
  local label_end = text:find(close_token, label_start, true)
  if not label_end then
    return nil, nil, start_index
  end

  local label = parser.trim(text:sub(label_start, label_end - 1))
  local next_index = label_end + #close_token
  return shape, label, next_index
end

local function ensure_node(model, identifier, explicit_label, explicit_shape)
  local known_node = model.nodes_by_id[identifier]
  if not known_node then
    known_node = {
      id = identifier,
      label = identifier,
      shape = "rect",
      group = current_group_path(model.group_stack),
    }
    model.nodes_by_id[identifier] = known_node
    model.node_order[#model.node_order + 1] = identifier
  end

  if explicit_label and explicit_label ~= "" then
    known_node.label = explicit_label:gsub('^"(.*)"$', "%1")
  end
  if explicit_shape then
    known_node.shape = explicit_shape
  end
  if not known_node.group then
    known_node.group = current_group_path(model.group_stack)
  end

  return known_node
end

local function parse_flow_node(text, start_index, model)
  local index = skip_spaces(text, start_index)
  local identifier_start = index

  while index <= #text and text:sub(index, index):match("[%w_.%-]") do
    index = index + 1
  end

  if index == identifier_start then
    return nil, start_index
  end

  local identifier = text:sub(identifier_start, index - 1)
  local shape, label, next_index = read_shape(text, index)
  if shape then
    return ensure_node(model, identifier, label, shape), next_index
  end

  return ensure_node(model, identifier), index
end

local function parse_flow_node_group(text, start_index, model)
  local first_node, next_index = parse_flow_node(text, start_index, model)
  if not first_node then
    return nil, start_index
  end

  local group = { first_node }
  local index = next_index

  while true do
    local separator_index = skip_spaces(text, index)
    if text:sub(separator_index, separator_index) ~= "&" then
      break
    end

    local next_node, after_node_index = parse_flow_node(text, separator_index + 1, model)
    if not next_node then
      return nil, start_index
    end

    group[#group + 1] = next_node
    index = after_node_index
  end

  return group, index
end

local function parse_flow_link(text, start_index)
  local index = skip_spaces(text, start_index)
  local raw_start = index

  while index <= #text and text:sub(index, index):match("[-=%.<>ox]") do
    index = index + 1
  end

  if index == raw_start then
    return nil, start_index
  end

  local raw_link = text:sub(raw_start, index - 1)
  local label

  if text:sub(index, index) == "|" then
    local label_end = text:find("|", index + 1, true)
    if not label_end then
      return nil, start_index
    end
    label = parser.trim(text:sub(index + 1, label_end - 1))
    index = label_end + 1
  end

  while index <= #text and text:sub(index, index):match("[-=%.<>ox]") do
    raw_link = raw_link .. text:sub(index, index)
    index = index + 1
  end

  return {
    label = label,
    raw = raw_link,
  }, index
end

local function parse_subgraph_label(line)
  local rest = parser.trim(line:sub(#"subgraph" + 1))
  local quoted_label = rest:match('^"(.-)"$')
  if quoted_label then
    return quoted_label
  end

  local identifier, bracket_label = rest:match("^(%S+)%[(.+)%]$")
  if bracket_label then
    return parser.trim(bracket_label), identifier
  end

  return rest, rest
end

local function add_warning(model, statement)
  model.warnings[#model.warnings + 1] = statement
end

local function parse_model(source)
  local lines = parser.split_lines(source)
  local direction, header_error = parser.parse_direction_header(lines[1] or "", {
    graph = "TD",
    flowchart = "TD",
  })
  if not direction then
    return nil, header_error
  end

  local model = {
    direction = direction,
    nodes_by_id = {},
    node_order = {},
    edges = {},
    groups = {},
    group_stack = {},
    warnings = {},
  }

  for line_number = 2, #lines do
    local statement = parser.strip_comment(lines[line_number]):gsub(";%s*$", "")
    if statement == "" then
      goto continue
    end

    local lowered = statement:lower()
    if lowered:match("^subgraph%s+") then
      local label, identifier = parse_subgraph_label(statement)
      local parent_path = current_group_path(model.group_stack)
      local path = parent_path and (parent_path .. " / " .. label) or label
      local group = {
        id = identifier or label,
        label = label,
        path = path,
      }
      model.groups[#model.groups + 1] = group
      model.group_stack[#model.group_stack + 1] = group
      goto continue
    end
    if lowered == "end" then
      if #model.group_stack == 0 then
        return nil, "unexpected subgraph end"
      end
      table.remove(model.group_stack)
      goto continue
    end
    if lowered:match("^style%s+") or lowered:match("^classdef%s+") or lowered:match("^class%s+") or lowered:match("^linkstyle%s+") then
      goto continue
    end
    if lowered:match("^click%s+") then
      add_warning(model, statement)
      goto continue
    end
    if lowered:match("^direction%s+") then
      local inline_direction = lowered:match("^direction%s+(%S+)$")
      if not inline_direction then
        add_warning(model, statement)
        goto continue
      end
      inline_direction = inline_direction:upper()
      if inline_direction == "TB" then
        inline_direction = "TD"
      end
      if inline_direction ~= "TD" and inline_direction ~= "BT" and inline_direction ~= "LR" and inline_direction ~= "RL" then
        add_warning(model, statement)
        goto continue
      end
      model.direction = inline_direction
      goto continue
    end

    local left_group, index = parse_flow_node_group(statement, 1, model)
    if not left_group then
      add_warning(model, statement)
      goto continue
    end

    local parsed_edge = false
    local line_supported = true
    while true do
      local link, next_index = parse_flow_link(statement, index)
      if not link then
        break
      end

      local right_group, after_right_group = parse_flow_node_group(statement, next_index, model)
      if not right_group then
        add_warning(model, statement)
        line_supported = false
        break
      end

      parsed_edge = true
      for _, left_node in ipairs(left_group) do
        for _, right_node in ipairs(right_group) do
          model.edges[#model.edges + 1] = {
            from = left_node.id,
            to = right_node.id,
            label = link.label,
            raw = link.raw,
          }
        end
      end

      left_group = right_group
      index = after_right_group
    end

    if not line_supported then
      goto continue
    end

    local remainder = parser.trim(statement:sub(index))
    if remainder ~= "" then
      add_warning(model, statement)
      goto continue
    end
    if not parsed_edge and #left_group == 0 then
      add_warning(model, statement)
      goto continue
    end

    ::continue::
  end

  if #model.group_stack > 0 then
    return nil, "unterminated subgraph"
  end

  if #model.node_order == 0 then
    return nil, "flowchart parser found no nodes"
  end

  return model
end

local function display_edges(model, edges)
  local reversed = model.direction == "BT" or model.direction == "RL"
  local displayed = {}

  for _, edge in ipairs(edges) do
    if reversed then
      displayed[#displayed + 1] = {
        from = edge.to,
        to = edge.from,
        label = edge.label,
      }
    else
      displayed[#displayed + 1] = {
        from = edge.from,
        to = edge.to,
        label = edge.label,
      }
    end
  end

  return displayed
end

local function ordered_subset(model, node_set)
  local ordered = {}
  for _, identifier in ipairs(model.node_order) do
    if node_set[identifier] then
      ordered[#ordered + 1] = identifier
    end
  end
  return ordered
end

local function build_tree(model, node_set, edges)
  local ordered_nodes = ordered_subset(model, node_set)
  local outgoing = {}
  local indegree = {}

  for _, identifier in ipairs(ordered_nodes) do
    outgoing[identifier] = {}
    indegree[identifier] = 0
  end

  for _, edge in ipairs(display_edges(model, edges)) do
    if node_set[edge.from] and node_set[edge.to] then
      outgoing[edge.from][#outgoing[edge.from] + 1] = edge
      indegree[edge.to] = (indegree[edge.to] or 0) + 1
    end
  end

  local roots = {}
  for _, identifier in ipairs(ordered_nodes) do
    if (indegree[identifier] or 0) == 0 then
      roots[#roots + 1] = identifier
    end
  end
  if #roots == 0 and ordered_nodes[1] then
    roots[1] = ordered_nodes[1]
  end

  local seen = {}
  local tree_children = {}
  local extra_edges = {}

  local function visit(identifier)
    seen[identifier] = true
    tree_children[identifier] = tree_children[identifier] or {}

    for _, edge in ipairs(outgoing[identifier] or {}) do
      local child_node = model.nodes_by_id[edge.to]
      if not seen[edge.to] then
        tree_children[identifier][#tree_children[identifier] + 1] = edge
        visit(edge.to)
      elseif child_node and child_node.shape == "terminal" then
        tree_children[identifier][#tree_children[identifier] + 1] = edge
      else
        extra_edges[#extra_edges + 1] = edge
      end
    end
  end

  for _, root in ipairs(roots) do
    if not seen[root] then
      visit(root)
    end
  end

  for _, identifier in ipairs(ordered_nodes) do
    if not seen[identifier] then
      roots[#roots + 1] = identifier
      visit(identifier)
    end
  end

  return {
    roots = roots,
    tree_children = tree_children,
    extra_edges = extra_edges,
  }
end

local function child_line(edge, child_text)
  if edge.label and edge.label ~= "" then
    return edge.label .. " -> " .. child_text
  end
  return child_text
end

local function render_vertical_subtree(node_id, tree_children, nodes_by_id, lines, prefix)
  for index, edge in ipairs(tree_children[node_id] or {}) do
    local is_last = index == #(tree_children[node_id] or {})
    local marker = is_last and "`- " or "|- "
    local child_prefix = prefix .. (is_last and "   " or "|  ")
    local child_text = format_node(nodes_by_id[edge.to])

    lines[#lines + 1] = prefix .. marker .. child_line(edge, child_text)
    render_vertical_subtree(edge.to, tree_children, nodes_by_id, lines, child_prefix)
  end
end

local function render_vertical_forest(model, node_set, edges)
  local tree = build_tree(model, node_set, edges)
  local lines = {}

  for root_index, root in ipairs(tree.roots) do
    if root_index > 1 then
      lines[#lines + 1] = ""
    end
    lines[#lines + 1] = format_node(model.nodes_by_id[root])
    render_vertical_subtree(root, tree.tree_children, model.nodes_by_id, lines, "")
  end

  if #tree.extra_edges > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[extra]"
    for _, edge in ipairs(tree.extra_edges) do
      local from_text = format_node(model.nodes_by_id[edge.from])
      local to_text = format_node(model.nodes_by_id[edge.to])
      if edge.label and edge.label ~= "" then
        lines[#lines + 1] = from_text .. " -" .. edge.label .. "-> " .. to_text
      else
        lines[#lines + 1] = from_text .. " -> " .. to_text
      end
    end
  end

  return parser.compact_blank_lines(lines)
end

local function render_horizontal_chain(model, node_id, tree_children)
  local parts = { format_node(model.nodes_by_id[node_id]) }
  local current = node_id

  while #(tree_children[current] or {}) == 1 do
    local edge = tree_children[current][1]
    local connector = edge.label and (" -" .. edge.label .. "-> ") or " -> "
    parts[#parts + 1] = connector .. format_node(model.nodes_by_id[edge.to])
    current = edge.to
  end

  return table.concat(parts), current
end

local function render_horizontal_branch(model, node_id, tree_children, lines, prefix)
  local line, final_node = render_horizontal_chain(model, node_id, tree_children)
  lines[#lines + 1] = prefix .. line

  local children = tree_children[final_node] or {}
  if #children <= 1 then
    return
  end

  local branch_prefix = prefix .. string.rep(" ", #format_node(model.nodes_by_id[final_node])) .. "   "
  for index, edge in ipairs(children) do
    local marker = index == #children and "`- " or "|- "
    local connector = edge.label and (edge.label .. " -> ") or ""
    render_horizontal_branch(model, edge.to, tree_children, lines, branch_prefix .. marker .. connector)
  end
end

local function render_horizontal_forest(model, node_set, edges)
  local tree = build_tree(model, node_set, edges)
  local lines = {}

  for root_index, root in ipairs(tree.roots) do
    if root_index > 1 then
      lines[#lines + 1] = ""
    end
    render_horizontal_branch(model, root, tree.tree_children, lines, "")
  end

  if #tree.extra_edges > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[extra]"
    for _, edge in ipairs(tree.extra_edges) do
      local from_text = format_node(model.nodes_by_id[edge.from])
      local to_text = format_node(model.nodes_by_id[edge.to])
      if edge.label and edge.label ~= "" then
        lines[#lines + 1] = from_text .. " -" .. edge.label .. "-> " .. to_text
      else
        lines[#lines + 1] = from_text .. " -> " .. to_text
      end
    end
  end

  return parser.compact_blank_lines(lines)
end

local function render_model(model)
  local grouped_edges = {}
  local cross_group_edges = {}
  local group_nodes = {}

  for _, group in ipairs(model.groups) do
    group_nodes[group.path] = {}
  end

  for _, identifier in ipairs(model.node_order) do
    local node = model.nodes_by_id[identifier]
    if node.group then
      group_nodes[node.group][identifier] = true
    end
  end

  for _, edge in ipairs(model.edges) do
    local from_group = model.nodes_by_id[edge.from].group
    local to_group = model.nodes_by_id[edge.to].group
    if from_group and from_group == to_group then
      grouped_edges[from_group] = grouped_edges[from_group] or {}
      grouped_edges[from_group][#grouped_edges[from_group] + 1] = edge
    elseif from_group or to_group then
      cross_group_edges[#cross_group_edges + 1] = edge
    end
  end

  local lines = {}
  local axis = (model.direction == "LR" or model.direction == "RL") and "horizontal" or "vertical"
  local renderer = axis == "horizontal" and render_horizontal_forest or render_vertical_forest
  local rendered_any_group = false

  for _, group in ipairs(model.groups) do
    local node_set = group_nodes[group.path]
    if node_set and next(node_set) then
      local group_lines = renderer(model, node_set, grouped_edges[group.path] or {})
      if #group_lines > 0 then
        if #lines > 0 then
          lines[#lines + 1] = ""
        end
        lines[#lines + 1] = "[" .. group.path .. "]"
        for _, line in ipairs(group_lines) do
          lines[#lines + 1] = line == "" and "" or ("  " .. line)
        end
        rendered_any_group = true
      end
    end
  end

  local ungrouped_nodes = {}
  for _, identifier in ipairs(model.node_order) do
    if not model.nodes_by_id[identifier].group then
      ungrouped_nodes[identifier] = true
    end
  end

  local ungrouped_edges = {}
  for _, edge in ipairs(model.edges) do
    local from_group = model.nodes_by_id[edge.from].group
    local to_group = model.nodes_by_id[edge.to].group
    if not from_group and not to_group then
      ungrouped_edges[#ungrouped_edges + 1] = edge
    end
  end

  if next(ungrouped_nodes) then
    local plain_lines = renderer(model, ungrouped_nodes, ungrouped_edges)
    if #plain_lines > 0 then
      if #lines > 0 then
        lines[#lines + 1] = ""
      end
      for _, line in ipairs(plain_lines) do
        lines[#lines + 1] = line
      end
    end
  end

  if #cross_group_edges > 0 and rendered_any_group then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[cross-group]"
    for _, edge in ipairs(display_edges(model, cross_group_edges)) do
      local from_text = format_node(model.nodes_by_id[edge.from])
      local to_text = format_node(model.nodes_by_id[edge.to])
      if edge.label and edge.label ~= "" then
        lines[#lines + 1] = from_text .. " -" .. edge.label .. "-> " .. to_text
      else
        lines[#lines + 1] = from_text .. " -> " .. to_text
      end
    end
  end

  if #lines == 0 then
    return nil, "flowchart renderer found no renderable content"
  end

  return parser.compact_blank_lines(lines)
end

local function render(source)
  local model, parse_error = parse_model(source)
  if not model then
    return nil, parse_error
  end

  local lines, render_error = render_model(model)
  if not lines then
    return nil, render_error
  end

  return parser.append_unsupported_lines(lines, model.warnings)
end

local M = {}
M.render_model = render_model
M.render = render
return M
