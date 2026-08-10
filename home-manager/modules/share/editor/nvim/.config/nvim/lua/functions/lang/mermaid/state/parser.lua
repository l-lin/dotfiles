local parser = require("functions.lang.mermaid.parser")
local text = require("functions.lang.mermaid.text")
local graph_builder = require("functions.lang.mermaid.state.graph_builder")

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
    notes = {},
    class_defs = {},
    class_assignments = {},
    node_styles = {},
    link_styles = {},
    warnings = {},
  }

  local subgraph_stack = {}
  local composite_state_ids = {}
  local pending_note = nil
  local start_count = 0
  local end_count = 0

  for index = 2, #lines do
    local line = lines[index]

    if pending_note then
      if line:lower() == "end note" then
        graph.notes[#graph.notes + 1] = {
          position = pending_note.position,
          state_id = pending_note.state_id,
          text = table.concat(pending_note.lines, "\n"),
        }
        pending_note = nil
      else
        pending_note.lines[#pending_note.lines + 1] = text.normalize_br_tags(line)
      end
      goto continue
    end

    local note_position, note_state_id = line:match("^[Nn]ote%s+(left)%s+of%s+([^%s]+)%s*$")
    if not note_position then
      note_position, note_state_id = line:match("^[Nn]ote%s+(right)%s+of%s+([^%s]+)%s*$")
    end
    if note_position and note_state_id then
      pending_note = {
        position = note_position,
        state_id = note_state_id,
        lines = {},
      }
      goto continue
    end

    local inline_direction = line:match("^direction%s+(%S+)%s*$")

    if inline_direction then
      local normalized_inline_direction = inline_direction:upper()
      if ({ TD = true, TB = true, LR = true, BT = true, RL = true })[normalized_inline_direction] then
        if #subgraph_stack > 0 then
          subgraph_stack[#subgraph_stack].direction = normalized_inline_direction
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

    local aliased_composite_label, aliased_composite_id = line:match('^state%s+"([^"]+)"%s+as%s+([^%s{]+)%s*{$')
    local composite_id = aliased_composite_id
    local composite_label = aliased_composite_label
    if not composite_id then
      composite_id = line:match("^state%s+([^%s{]+)%s*{$")
      composite_label = composite_id
    end

    if composite_id then
      subgraph_stack[#subgraph_stack + 1] = {
        id = composite_id,
        label = text.normalize_br_tags(composite_label),
        node_ids = {},
        node_id_set = {},
        children = {},
      }
      composite_state_ids[composite_id] = true
      graph_builder.remove_node_by_id(graph, composite_id)
      goto continue
    end

    if line == "}" then
      local completed = table.remove(subgraph_stack)
      if not completed then
        parser.add_warning(graph, line)
      else
        if #subgraph_stack > 0 then
          subgraph_stack[#subgraph_stack].children[#subgraph_stack[#subgraph_stack].children + 1] = completed
        else
          graph.subgraphs[#graph.subgraphs + 1] = completed
        end
      end
      goto continue
    end

    local state_alias_label, state_alias_id = line:match('^state%s+"([^"]+)"%s+as%s+([^%s]+)%s*$')
    if state_alias_id then
      graph_builder.add_node(graph, subgraph_stack, {
        id = state_alias_id,
        label = text.normalize_br_tags(state_alias_label),
        shape = "rounded",
      })
      goto continue
    end

    local before_arrow, after_arrow = line:match("^(.-)%-%->%s*(.+)$")
    if before_arrow and after_arrow then
      local source_id = text.trim(before_arrow)
      local target_segment = text.trim(after_arrow)
      local target_id = target_segment
      local raw_label = nil

      local matched_target_id, matched_label = target_segment:match("^(.-)%s*:%s*(.+)$")
      if matched_target_id and matched_label then
        target_id = text.trim(matched_target_id)
        raw_label = text.trim(matched_label)
      end

      if source_id ~= "" and target_id ~= "" then
        local normalized_source = source_id
        local normalized_target = target_id

        if normalized_source == "[*]" then
          start_count = start_count + 1
          normalized_source = start_count == 1 and "_start" or ("_start" .. start_count)
          graph_builder.add_node(graph, subgraph_stack, {
            id = normalized_source,
            label = "",
            shape = "state-start",
          })
        elseif not composite_state_ids[normalized_source] then
          graph_builder.ensure_node(graph, subgraph_stack, normalized_source)
        end

        if normalized_target == "[*]" then
          end_count = end_count + 1
          normalized_target = end_count == 1 and "_end" or ("_end" .. end_count)
          graph_builder.add_node(graph, subgraph_stack, {
            id = normalized_target,
            label = "",
            shape = "state-end",
          })
        elseif not composite_state_ids[normalized_target] then
          graph_builder.ensure_node(graph, subgraph_stack, normalized_target)
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
      graph_builder.add_node(graph, subgraph_stack, {
        id = described_state_id,
        label = text.normalize_br_tags(text.trim(described_state_label)),
        shape = "rounded",
      })
      goto continue
    end

    parser.add_warning(graph, line)

    ::continue::
  end

  if pending_note then
    parser.add_warning(graph, "unterminated note block")
  end

  if #subgraph_stack > 0 then
    parser.add_warning(graph, "unterminated state block")
  end

  return graph
end

local M = {}
M.parse = parse
return M
