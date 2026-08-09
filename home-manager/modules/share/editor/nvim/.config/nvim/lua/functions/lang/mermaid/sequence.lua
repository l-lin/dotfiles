local parser = require("functions.lang.mermaid.parser")

local function render(source)
  local participant_labels = {}
  local participant_order = {}
  local events = {}
  local warnings = {}
  local auto_number = false
  local message_count = 0

  local function add_warning(statement)
    warnings[#warnings + 1] = statement
  end

  local function ensure_participant(identifier, explicit_label)
    if not participant_labels[identifier] then
      participant_order[#participant_order + 1] = identifier
    end
    participant_labels[identifier] = explicit_label or participant_labels[identifier] or identifier
    return participant_labels[identifier]
  end

  local function participant_label(identifier)
    return ensure_participant(identifier)
  end

  local function add_note(text)
    events[#events + 1] = {
      kind = "note",
      text = text,
    }
  end

  local function add_activation(identifier, active)
    ensure_participant(identifier)
    events[#events + 1] = {
      kind = active and "activate" or "deactivate",
      participant = identifier,
    }
  end

  local function add_message(from_identifier, to_identifier, arrow, message_label)
    ensure_participant(from_identifier)
    ensure_participant(to_identifier)

    if auto_number then
      message_count = message_count + 1
      message_label = string.format("%d. %s", message_count, message_label)
    end

    events[#events + 1] = {
      kind = "message",
      from = from_identifier,
      to = to_identifier,
      fill = (arrow:find("%-%-") or arrow:find("%.")) and "." or "-",
      label = message_label,
    }
  end

  local lines = parser.split_lines(source)
  for line_number = 2, #lines do
    local statement = parser.strip_comment(lines[line_number])
    if statement == "" then
      goto continue
    end

    if statement == "autonumber" then
      auto_number = true
      goto continue
    end

    local actor_identifier, actor_alias = statement:match("^actor%s+(%S+)%s+as%s+(.+)$")
    if actor_identifier then
      ensure_participant(actor_identifier, parser.trim(actor_alias))
      goto continue
    end

    actor_identifier = statement:match("^actor%s+(%S+)$")
    if actor_identifier then
      ensure_participant(actor_identifier)
      goto continue
    end

    local participant_identifier, participant_alias = statement:match("^participant%s+(%S+)%s+as%s+(.+)$")
    if participant_identifier then
      ensure_participant(participant_identifier, parser.trim(participant_alias))
      goto continue
    end

    participant_identifier = statement:match("^participant%s+(%S+)$")
    if participant_identifier then
      ensure_participant(participant_identifier)
      goto continue
    end

    local activation_identifier = statement:match("^activate%s+(%S+)$")
    if activation_identifier then
      add_activation(activation_identifier, true)
      goto continue
    end

    local deactivation_identifier = statement:match("^deactivate%s+(%S+)$")
    if deactivation_identifier then
      add_activation(deactivation_identifier, false)
      goto continue
    end

    local alt_label = statement:match("^alt%s+(.+)$")
    if alt_label then
      add_note("[alt] " .. parser.trim(alt_label))
      goto continue
    end

    local opt_label = statement:match("^opt%s+(.+)$")
    if opt_label then
      add_note("[opt] " .. parser.trim(opt_label))
      goto continue
    end

    local loop_label = statement:match("^loop%s+(.+)$")
    if loop_label then
      add_note("[loop] " .. parser.trim(loop_label))
      goto continue
    end

    local else_label = statement:match("^else%s*(.*)$")
    if else_label then
      add_note(parser.trim("[else] " .. else_label))
      goto continue
    end

    local inline_note = statement:match("^[Nn]ote%s+.+:%s*(.+)$")
    if inline_note then
      add_note("[note] " .. parser.trim(inline_note))
      goto continue
    end

    if statement == "end" then
      goto continue
    end

    local head, message_label = statement:match("^(.-)%s*:%s*(.+)$")
    if not head then
      add_warning(statement)
      goto continue
    end

    local from_identifier, arrow, to_identifier = head:match("^([%w_.]+)%s*([<>%.=xo()%-]+)%s*([%w_.]+)$")
    if not from_identifier then
      add_warning(statement)
      goto continue
    end

    add_message(from_identifier, to_identifier, arrow, parser.trim(message_label))

    ::continue::
  end

  if #events == 0 or #participant_order == 0 then
    return nil, "sequence parser found no renderable messages"
  end

  local gap_width = 5
  local left_columns = {}
  local centers = {}
  local box_widths = {}
  local total_width = 0

  for _, identifier in ipairs(participant_order) do
    local label = participant_label(identifier)
    local box_width = #label + 4
    local left_column = total_width == 0 and 1 or total_width + gap_width + 1

    left_columns[identifier] = left_column
    centers[identifier] = left_column + math.floor((box_width - 1) / 2)
    box_widths[identifier] = box_width
    total_width = left_column + box_width - 1
  end

  for _, event in ipairs(events) do
    if event.kind == "message" then
      local label_start = math.min(centers[event.from], centers[event.to]) + 2
      total_width = math.max(total_width, label_start + #event.label - 1)
    end
  end

  local function blank_chars()
    local chars = {}
    for index = 1, total_width do
      chars[index] = " "
    end
    return chars
  end

  local function write_text(chars, start_column, text)
    for offset = 1, #text do
      chars[start_column + offset - 1] = text:sub(offset, offset)
    end
  end

  local function join_chars(chars)
    return table.concat(chars):gsub("%s+$", "")
  end

  local active_counts = {}

  local function lane_chars()
    local chars = blank_chars()
    for _, identifier in ipairs(participant_order) do
      chars[centers[identifier]] = (active_counts[identifier] or 0) > 0 and "!" or "|"
    end
    return chars
  end

  local output = {}
  local top_chars = blank_chars()
  local middle_chars = blank_chars()
  local bottom_chars = blank_chars()

  for _, identifier in ipairs(participant_order) do
    local label = participant_label(identifier)
    local left_column = left_columns[identifier]
    local box_width = box_widths[identifier]
    local center_column = centers[identifier]

    write_text(top_chars, left_column, "+" .. string.rep("-", box_width - 2) .. "+")
    write_text(middle_chars, left_column, "| " .. label .. " |")

    for column = left_column, left_column + box_width - 1 do
      if column == left_column or column == left_column + box_width - 1 or column == center_column then
        bottom_chars[column] = "+"
      else
        bottom_chars[column] = "-"
      end
    end
  end

  output[#output + 1] = join_chars(top_chars)
  output[#output + 1] = join_chars(middle_chars)
  output[#output + 1] = join_chars(bottom_chars)
  output[#output + 1] = join_chars(lane_chars())

  for _, event in ipairs(events) do
    if event.kind == "note" then
      output[#output + 1] = event.text
    elseif event.kind == "activate" then
      active_counts[event.participant] = (active_counts[event.participant] or 0) + 1
      output[#output + 1] = join_chars(lane_chars())
    elseif event.kind == "deactivate" then
      active_counts[event.participant] = math.max((active_counts[event.participant] or 0) - 1, 0)
      output[#output + 1] = join_chars(lane_chars())
    else
      local label_chars = lane_chars()
      local arrow_chars = lane_chars()
      local spacer_chars = lane_chars()
      local from_center = centers[event.from]
      local to_center = centers[event.to]
      local left_center = math.min(from_center, to_center)
      local right_center = math.max(from_center, to_center)

      write_text(label_chars, left_center + 2, event.label)

      if from_center == to_center then
        write_text(arrow_chars, from_center, "+--+")
        write_text(spacer_chars, from_center, "|<+")
      elseif from_center < to_center then
        arrow_chars[from_center] = "+"
        for column = from_center + 1, to_center - 2 do
          arrow_chars[column] = event.fill
        end
        arrow_chars[to_center - 1] = ">"
        arrow_chars[to_center] = "|"
      else
        arrow_chars[left_center] = "|"
        arrow_chars[left_center + 1] = "<"
        for column = left_center + 2, right_center - 1 do
          arrow_chars[column] = event.fill
        end
        arrow_chars[right_center] = "+"
      end

      output[#output + 1] = join_chars(label_chars)
      output[#output + 1] = join_chars(arrow_chars)
      output[#output + 1] = join_chars(spacer_chars)
    end
  end

  return parser.append_unsupported_lines(output, warnings)
end

local M = {}
M.render = render
return M
