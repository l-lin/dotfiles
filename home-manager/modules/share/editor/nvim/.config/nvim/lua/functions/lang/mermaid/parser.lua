local text = require("functions.lang.mermaid.text")

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

local function split_lines(source)
  return text.split_lines(source)
end

local function trim(value)
  return text.trim(value)
end

local function compact_blank_lines(lines)
  local compacted = {}
  local previous_blank = false

  for _, line in ipairs(lines) do
    local blank = text.is_blank(line)
    if not (blank and previous_blank) then
      compacted[#compacted + 1] = line
    end
    previous_blank = blank
  end

  while compacted[#compacted] == "" do
    table.remove(compacted)
  end

  return compacted
end

local function preprocess_source(source)
  local lines = {}
  for _, raw_line in ipairs(split_lines(source)) do
    local normalized = trim(raw_line)
    if normalized ~= "" and normalized:sub(1, 2) ~= "%%" then
      lines[#lines + 1] = normalized
    end
  end
  return lines
end

local function diagram_kind(source)
  for _, raw_line in ipairs(split_lines(source)) do
    local header = trim(raw_line)
    if header ~= "" then
      local keyword = header:match("^(%S+)")
      if not keyword then
        return nil
      end

      local lowered = keyword:lower()
      if lowered == "graph" or lowered == "flowchart" then
        return "flowchart"
      end
      if lowered:match("^statediagram") then
        return "state"
      end
      if lowered == "sequencediagram" then
        return "sequence"
      end
      return nil
    end
  end
  return nil
end

local function find_mermaid_blocks(markdown_lines)
  local blocks = {}
  local current_block = nil

  for index, line in ipairs(markdown_lines) do
    if not current_block then
      local indent = line:match("^(%s*)```mermaid%s*$")
      if indent then
        current_block = {
          start_row = index - 1,
          indent = indent,
          source_lines = {},
        }
      end
    else
      if line:match("^%s*```%s*$") then
        current_block.end_row = index - 1
        current_block.source = table.concat(current_block.source_lines, "\n")
        blocks[#blocks + 1] = current_block
        current_block = nil
      else
        current_block.source_lines[#current_block.source_lines + 1] = line
      end
    end
  end

  return blocks
end

local function append_unsupported_lines(lines, warnings)
  if not warnings or #warnings == 0 then
    return lines
  end

  local seen = {}
  local rendered_warnings = {}

  for _, warning in ipairs(warnings) do
    local normalized = trim(warning)
    if normalized ~= "" and not seen[normalized] then
      seen[normalized] = true
      rendered_warnings[#rendered_warnings + 1] = "[unsupported: " .. normalized .. "]"
    end
  end

  if #rendered_warnings == 0 then
    return lines
  end

  lines[#lines + 1] = ""
  for _, warning_line in ipairs(rendered_warnings) do
    lines[#lines + 1] = warning_line
  end

  return lines
end

local function add_warning(graph, raw_line)
  graph.warnings[#graph.warnings + 1] = trim(raw_line)
end

local function array_copy(values)
  local copied = {}
  for index, value in ipairs(values) do
    copied[index] = value
  end
  return copied
end

local function shallow_copy(values)
  local copied = {}
  for key, value in pairs(values) do
    copied[key] = value
  end
  return copied
end

local function has_value(list, wanted)
  for _, value in ipairs(list) do
    if value == wanted then
      return true
    end
  end
  return false
end

local function track_in_subgraph(subgraph_stack, node_id)
  if #subgraph_stack == 0 then
    return
  end

  local current = subgraph_stack[#subgraph_stack]
  if not has_value(current.node_ids, node_id) then
    current.node_ids[#current.node_ids + 1] = node_id
  end
end

local function register_node(graph, subgraph_stack, node)
  if not graph.nodes[node.id] then
    graph.nodes[node.id] = node
    graph.node_order[#graph.node_order + 1] = node.id
  end
  track_in_subgraph(subgraph_stack, node.id)
end

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

local function parse_style_props(props_string)
  local cleaned = props_string:gsub(";%s*$", "")
  local props = {}

  for pair in cleaned:gmatch("[^,]+") do
    local colon_index = pair:find(":", 1, true)
    if colon_index and colon_index > 1 then
      local key = trim(pair:sub(1, colon_index - 1))
      local value = trim(pair:sub(colon_index + 1))
      if key ~= "" and value ~= "" then
        props[key] = value
      end
    end
  end

  return props
end

local function arrow_style_from_op(operator)
  if operator == "-.->" or operator == "-.-" or operator == ".->" then
    return "dotted"
  end
  if operator == "==>" or operator == "===" then
    return "thick"
  end
  return "solid"
end

local function text_arrow_style_from_ops(open_operator, close_operator)
  if open_operator == "-." or close_operator == ".->" or close_operator == "-.-" then
    return "dotted"
  end
  if open_operator == "==" or close_operator == "==>" or close_operator == "===" then
    return "thick"
  end
  return "solid"
end

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

local function consume_node_group(text_value, graph, subgraph_stack)
  local first = consume_node(trim(text_value), graph, subgraph_stack)
  if not first then
    return nil
  end

  local identifiers = { first.id }
  local remaining = trim(first.remaining)

  while remaining:sub(1, 1) == "&" do
    local next_node = consume_node(trim(remaining:sub(2)), graph, subgraph_stack)
    if not next_node then
      break
    end
    identifiers[#identifiers + 1] = next_node.id
    remaining = trim(next_node.remaining)
  end

  return {
    ids = identifiers,
    remaining = remaining,
  }
end

local function consume_arrow(text_value)
  local remaining = trim(text_value)
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
        local raw_label = trim(rest:sub(2, label_end - 1))
        if raw_label ~= "" then
          edge_label = text.normalize_br_tags(raw_label)
        end
        rest = rest:sub(label_end + 1)
      end

      return {
        label = edge_label,
        style = arrow_style_from_op(operator),
        has_arrow_start = has_arrow_start,
        has_arrow_end = operator:sub(-1) == ">",
        remaining = trim(rest),
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
          remaining = trim(after_open:sub(best_position + 1 + #best_close)),
        }
      end
    end
  end

  return nil
end

local function parse_edge_line(line, graph, subgraph_stack)
  local first_group = consume_node_group(line, graph, subgraph_stack)
  if not first_group or #first_group.ids == 0 then
    return false
  end

  local remaining = trim(first_group.remaining)
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

    remaining = trim(next_group.remaining)

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

local function parse_flowchart(lines)
  local keyword, direction = lines[1]:match("^(%S+)%s+(%S+)%s*$")
  if not keyword or not direction then
    return nil, string.format('Invalid mermaid header: "%s". Expected "graph TD", "flowchart LR", "stateDiagram-v2", etc.', lines[1])
  end

  local lowered_keyword = keyword:lower()
  local normalized_direction = direction:upper()
  if lowered_keyword ~= "graph" and lowered_keyword ~= "flowchart" then
    return nil, string.format('Invalid mermaid header: "%s". Expected "graph TD", "flowchart LR", "stateDiagram-v2", etc.', lines[1])
  end
  if not ({ TD = true, TB = true, LR = true, BT = true, RL = true })[normalized_direction] then
    return nil, string.format('Invalid mermaid header: "%s". Expected "graph TD", "flowchart LR", "stateDiagram-v2", etc.', lines[1])
  end

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
    local lowered = line:lower()

    local class_def_name, class_def_props = line:match("^classDef%s+([%w_]+)%s+(.+)$")
    if class_def_name and class_def_props then
      graph.class_defs[class_def_name] = parse_style_props(class_def_props)
      goto continue
    end

    local class_targets, class_name = line:match("^class%s+([%w_,%-]+)%s+([%w_]+)$")
    if class_targets and class_name then
      for node_id in class_targets:gmatch("[^,]+") do
        graph.class_assignments[trim(node_id)] = class_name
      end
      goto continue
    end

    local styled_targets, styled_props = line:match("^style%s+([%w_,%-]+)%s+(.+)$")
    if styled_targets and styled_props then
      local props = parse_style_props(styled_props)
      for node_id in styled_targets:gmatch("[^,]+") do
        local normalized_id = trim(node_id)
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
        local style_props = parse_style_props(props)
        local normalized_target = trim(target)
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
        subgraph_label = text.normalize_br_tags(trim(subgraph_rest))
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
        add_warning(graph, line)
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
      add_warning(graph, line)
    end

    ::continue::
  end

  if #subgraph_stack > 0 then
    add_warning(graph, "unterminated subgraph")
  end

  return graph
end

local function register_state_node(graph, composite_stack, node)
  if not graph.nodes[node.id] then
    graph.nodes[node.id] = node
    graph.node_order[#graph.node_order + 1] = node.id
  end
  track_in_subgraph(composite_stack, node.id)
end

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

local function parse_state_diagram(lines)
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
        local style_props = parse_style_props(props)
        local normalized_target = trim(target)
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
        add_warning(graph, line)
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
      local source_id = trim(before_arrow)
      local target_segment = trim(after_arrow)
      local target_id = target_segment
      local raw_label = nil

      local matched_target_id, matched_label = target_segment:match("^(.-)%s*:%s*(.+)$")
      if matched_target_id and matched_label then
        target_id = trim(matched_target_id)
        raw_label = trim(matched_label)
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
        label = text.normalize_br_tags(trim(described_state_label)),
        shape = "rounded",
      })
      goto continue
    end

    add_warning(graph, line)

    ::continue::
  end

  if #composite_stack > 0 then
    add_warning(graph, "unterminated state block")
  end

  return graph
end

local function parse_mermaid(source)
  local lines = preprocess_source(source)
  if #lines == 0 then
    return nil, "Empty mermaid diagram"
  end

  local lowered_header = lines[1]:lower()
  if lowered_header == "statediagram" or lowered_header == "statediagram-v2" then
    return parse_state_diagram(lines)
  end

  return parse_flowchart(lines)
end

local M = {}
M.trim = trim
M.split_lines = split_lines
M.compact_blank_lines = compact_blank_lines
M.diagram_kind = diagram_kind
M.find_mermaid_blocks = find_mermaid_blocks
M.append_unsupported_lines = append_unsupported_lines
M.parse_mermaid = parse_mermaid
M.preprocess_source = preprocess_source
return M
