local flowchart = require("functions.lang.mermaid.flowchart")
local parser = require("functions.lang.mermaid.parser")

local function current_group_path(group_stack)
  if #group_stack == 0 then
    return nil
  end
  return group_stack[#group_stack]
end

local function add_warning(model, statement)
  model.warnings[#model.warnings + 1] = statement
end

local function terminal_identifier(scope_path, terminal_role)
  return string.format("%s::%s_terminal", scope_path or "__root__", terminal_role)
end

local function ensure_state(model, token, scope_path, terminal_role)
  local normalized = parser.trim(token)
  local identifier = normalized
  local shape = "rect"
  local label = normalized

  if normalized == "[*]" then
    identifier = terminal_identifier(scope_path, terminal_role == "end" and "end" or "start")
    shape = "terminal"
    label = "(*)"
  end

  local known_state = model.nodes_by_id[identifier]
  if not known_state then
    known_state = {
      id = identifier,
      label = label,
      shape = shape,
      group = scope_path,
    }
    model.nodes_by_id[identifier] = known_state
    model.node_order[#model.node_order + 1] = identifier
  end

  if scope_path and not known_state.group then
    known_state.group = scope_path
  end

  return known_state
end

local function start_note(model, position, target)
  model.open_note = {
    position = position,
    target = target,
    lines = {},
  }
end

local function finish_note(model)
  if not model.open_note then
    return
  end
  model.notes[#model.notes + 1] = model.open_note
  model.open_note = nil
end

local function parse_model(source)
  local lines = parser.split_lines(source)
  local direction, header_error = parser.parse_direction_header(lines[1] or "", {
    ["stateDiagram-v2"] = "TD",
    ["stateDiagram"] = "TD",
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
    notes = {},
    open_note = nil,
    warnings = {},
  }

  for line_number = 2, #lines do
    local statement = parser.strip_comment(lines[line_number]):gsub(";%s*$", "")

    if model.open_note then
      if statement:lower() == "end note" then
        finish_note(model)
      elseif statement ~= "" then
        model.open_note.lines[#model.open_note.lines + 1] = statement
      end
      goto continue
    end

    if statement == "" then
      goto continue
    end

    local lowered = statement:lower()
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

    local note_position, note_target, note_text = statement:match("^note%s+(%w+)%s+of%s+([%w_.%-]+)%s*:%s*(.+)$")
    if note_position and note_target then
      model.notes[#model.notes + 1] = {
        position = note_position:lower(),
        target = note_target,
        lines = { parser.trim(note_text) },
      }
      goto continue
    end

    note_position, note_target = statement:match("^note%s+(%w+)%s+of%s+([%w_.%-]+)$")
    if note_position and note_target then
      start_note(model, note_position:lower(), note_target)
      goto continue
    end

    if lowered == "end note" then
      add_warning(model, statement)
      goto continue
    end

    local group_name = statement:match("^state%s+(.+)%s+%{$") or statement:match("^state%s+(.+)%{$")
    if group_name then
      group_name = parser.trim(group_name)
      local parent_path = current_group_path(model.group_stack)
      ensure_state(model, group_name, parent_path)
      local path = parent_path and (parent_path .. " / " .. group_name) or group_name
      model.groups[#model.groups + 1] = {
        id = group_name,
        label = group_name,
        path = path,
      }
      model.group_stack[#model.group_stack + 1] = path
      goto continue
    end

    if statement == "}" then
      if #model.group_stack == 0 then
        return nil, "unexpected state block end"
      end
      table.remove(model.group_stack)
      goto continue
    end

    if statement:match("^state%s+") then
      local standalone_state = statement:match("^state%s+([%w_.%-]+)$")
      if standalone_state then
        ensure_state(model, standalone_state, current_group_path(model.group_stack))
        goto continue
      end
      add_warning(model, statement)
      goto continue
    end

    if statement:match("^choice%s+") or statement:match("^fork%s+") then
      add_warning(model, statement)
      goto continue
    end

    local from_state, remainder = statement:match("^(.-)%-%->%s*(.+)$")
    if not from_state then
      add_warning(model, statement)
      goto continue
    end

    local to_state, transition_label = remainder:match("^(.-)%s*:%s*(.+)$")
    if not to_state then
      to_state = remainder
    end

    from_state = parser.trim(from_state)
    to_state = parser.trim(to_state)
    if from_state == "" or to_state == "" then
      add_warning(model, statement)
      goto continue
    end

    local scope_path = current_group_path(model.group_stack)
    local from_node = ensure_state(model, from_state, scope_path, from_state == "[*]" and "start" or nil)
    local to_node = ensure_state(model, to_state, scope_path, to_state == "[*]" and "end" or nil)
    model.edges[#model.edges + 1] = {
      from = from_node.id,
      to = to_node.id,
      label = transition_label and parser.trim(transition_label) or nil,
    }

    ::continue::
  end

  if model.open_note then
    add_warning(model, string.format("unterminated note %s of %s", model.open_note.position, model.open_note.target))
    model.open_note = nil
  end
  if #model.group_stack > 0 then
    return nil, "unterminated state block"
  end
  if #model.node_order == 0 then
    return nil, "state parser found no states"
  end

  return model
end

local function append_notes(lines, model)
  for _, note in ipairs(model.notes) do
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("[note %s of %s]", note.position, note.target)
    for _, note_line in ipairs(note.lines) do
      lines[#lines + 1] = "  " .. note_line
    end
  end
  return lines
end

local function render(source)
  local model, parse_error = parse_model(source)
  if not model then
    return nil, parse_error
  end

  local lines, render_error = flowchart.render_model(model)
  if not lines then
    return nil, render_error
  end

  append_notes(lines, model)
  parser.append_unsupported_lines(lines, model.warnings)
  return parser.compact_blank_lines(lines)
end

local M = {}
M.render = render
return M
