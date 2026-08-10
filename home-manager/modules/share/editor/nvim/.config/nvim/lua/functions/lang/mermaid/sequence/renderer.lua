local canvas = require("functions.lang.mermaid.canvas")
local parser = require("functions.lang.mermaid.parser")
local sequence_parser = require("functions.lang.mermaid.sequence.parser")
local text = require("functions.lang.mermaid.text")

---Creates a mapping from actor IDs to their corresponding indexes in the diagram's actors list.
---@param diagram dotfiles.mermaid.sequence.Graph
---@return table<string, number> A mapping from actor IDs to their indexes.
local function actor_index_map(diagram)
  local index_map = {}
  for index, actor in ipairs(diagram.actors) do
    index_map[actor.id] = index
  end
  return index_map
end

---Renders a sequence diagram from the given source string.
---@param source string The source string representing the sequence diagram.
---@return string[]|nil A table of strings representing the rendered diagram, or nil if an
---@return string|nil An error message if rendering failed, or nil if successful.
local function render(source)
  if parser.diagram_kind(source) ~= "sequence" then
    return nil, "unsupported diagram kind"
  end

  local diagram, parse_error = sequence_parser.parse(source)
  if not diagram then
    return nil, parse_error
  end
  if #diagram.actors == 0 then
    return nil, "sequence parser found no renderable messages"
  end

  local H = "─"
  local V = "│"
  local TL = "┌"
  local TR = "┐"
  local BL = "└"
  local BR = "┘"
  local JT = "┬"
  local JB = "┴"
  local JL = "├"
  local JR = "┤"

  local actor_indexes = actor_index_map(diagram)
  local actor_box_widths = {}
  local actor_box_heights = {}
  local half_boxes = {}
  local adjacency_widths = {}

  for index = 1, math.max(#diagram.actors - 1, 0) do
    adjacency_widths[index] = 0
  end

  for index, actor in ipairs(diagram.actors) do
    actor_box_widths[index] = text.max_line_width(actor.label) + 4
    half_boxes[index] = math.ceil(actor_box_widths[index] / 2)
    actor_box_heights[index] = text.line_count(actor.label) + 2
  end

  local actor_box_height = 3
  for _, height in ipairs(actor_box_heights) do
    actor_box_height = math.max(actor_box_height, height)
  end

  for _, message in ipairs(diagram.messages) do
    local from_index = actor_indexes[message.from]
    local to_index = actor_indexes[message.to]
    if from_index ~= to_index then
      local low = math.min(from_index, to_index)
      local high = math.max(from_index, to_index)
      local needed = text.max_line_width(message.label) + 4
      local gaps = high - low
      local per_gap = math.ceil(needed / gaps)
      for gap = low, high - 1 do
        adjacency_widths[gap] = math.max(adjacency_widths[gap], per_gap)
      end
    end
  end

  local lifeline_x = {}
  lifeline_x[1] = half_boxes[1]
  for index = 2, #diagram.actors do
    local gap = math.max(half_boxes[index - 1] + half_boxes[index] + 2, (adjacency_widths[index - 1] or 0) + 2, 10)
    lifeline_x[index] = lifeline_x[index - 1] + gap
  end

  local message_arrow_y = {}
  local message_label_y = {}
  local block_start_y = {}
  local block_end_y = {}
  local divider_y = {}
  local note_positions = {}
  local cursor_y = actor_box_height

  for message_index = 1, #diagram.messages do
    for block_index, block in ipairs(diagram.blocks) do
      if block.start_index == message_index - 1 then
        cursor_y = cursor_y + 2
        block_start_y[block_index] = cursor_y - 1
      end
    end

    for block_index, block in ipairs(diagram.blocks) do
      for divider_index, divider in ipairs(block.dividers) do
        if divider.index == message_index - 1 then
          cursor_y = cursor_y + 1
          divider_y[string.format("%d:%d", block_index, divider_index)] = cursor_y
          cursor_y = cursor_y + 1
        end
      end
    end

    cursor_y = cursor_y + 1
    local message = diagram.messages[message_index]
    local is_self = message.from == message.to
    local message_line_count = text.line_count(message.label)

    if is_self then
      message_label_y[message_index] = cursor_y + 1
      message_arrow_y[message_index] = cursor_y
      cursor_y = cursor_y + 2 + message_line_count
    else
      message_label_y[message_index] = cursor_y
      message_arrow_y[message_index] = cursor_y + message_line_count
      cursor_y = cursor_y + message_line_count + 1
    end

    for _, note in ipairs(diagram.notes) do
      if note.after_index == message_index - 1 then
        cursor_y = cursor_y + 1
        local note_lines = text.split_label_lines(note.text)
        local note_width = 4
        for _, note_line in ipairs(note_lines) do
          note_width = math.max(note_width, text.char_len(note_line) + 4)
        end
        local note_height = #note_lines + 2

        local actor_position = actor_indexes[note.actor_ids[1]] or 1
        local note_x
        if note.position == "left" then
          note_x = lifeline_x[actor_position] - note_width - 1
        elseif note.position == "right" then
          note_x = lifeline_x[actor_position] + 2
        else
          if #note.actor_ids >= 2 then
            local second_position = actor_indexes[note.actor_ids[2]] or actor_position
            note_x = math.floor((lifeline_x[actor_position] + lifeline_x[second_position]) / 2)
              - math.floor(note_width / 2)
          else
            note_x = lifeline_x[actor_position] - math.floor(note_width / 2)
          end
        end
        note_x = math.max(0, note_x)

        note_positions[#note_positions + 1] = {
          x = note_x,
          y = cursor_y,
          width = note_width,
          height = note_height,
          lines = note_lines,
        }
        cursor_y = cursor_y + note_height
      end
    end

    for block_index, block in ipairs(diagram.blocks) do
      if block.end_index == message_index - 1 then
        cursor_y = cursor_y + 1
        block_end_y[block_index] = cursor_y
        cursor_y = cursor_y + 1
      end
    end
  end

  cursor_y = cursor_y + 1
  local footer_y = cursor_y
  local total_height = footer_y + actor_box_height
  local last_lifeline = lifeline_x[#lifeline_x] or 0
  local last_half_box = half_boxes[#half_boxes] or 0
  local total_width = last_lifeline + last_half_box + 2

  for _, message in ipairs(diagram.messages) do
    if message.from == message.to then
      local actor_position = actor_indexes[message.from]
      total_width = math.max(total_width, lifeline_x[actor_position] + 8 + text.max_line_width(message.label))
    end
  end
  for _, note_position in ipairs(note_positions) do
    total_width = math.max(total_width, note_position.x + note_position.width + 1)
  end

  local rendered = canvas.mk_canvas(total_width, total_height - 1)

  local function set_char(x, y, char)
    if x < 0 or y < 0 then
      return
    end
    canvas.increase_size(rendered, x, y)
    rendered[x][y] = char
  end

  local function draw_actor_box(center_x, top_y, label)
    local lines = text.split_label_lines(label)
    local max_width = text.max_line_width(label)
    local box_width = max_width + 4
    local box_height = #lines + 2
    local left_x = center_x - math.floor(box_width / 2)

    set_char(left_x, top_y, TL)
    for x = 1, box_width - 2 do
      set_char(left_x + x, top_y, H)
    end
    set_char(left_x + box_width - 1, top_y, TR)

    for line_index, line in ipairs(lines) do
      local row = top_y + line_index
      set_char(left_x, row, V)
      set_char(left_x + box_width - 1, row, V)
      local line_start = left_x + 2 + math.floor((max_width - text.char_len(line)) / 2)
      canvas.draw_text(rendered, { x = line_start, y = row }, line, true)
    end

    local bottom_y = top_y + box_height - 1
    set_char(left_x, bottom_y, BL)
    for x = 1, box_width - 2 do
      set_char(left_x + x, bottom_y, H)
    end
    set_char(left_x + box_width - 1, bottom_y, BR)
  end

  for index = 1, #diagram.actors do
    local x = lifeline_x[index]
    for y = actor_box_height, footer_y do
      set_char(x, y, V)
    end
  end

  for index, actor in ipairs(diagram.actors) do
    draw_actor_box(lifeline_x[index], 0, actor.label)
    draw_actor_box(lifeline_x[index], footer_y, actor.label)
    set_char(lifeline_x[index], actor_box_height - 1, JT)
    set_char(lifeline_x[index], footer_y, JB)
  end

  for message_index, message in ipairs(diagram.messages) do
    local from_index = actor_indexes[message.from]
    local to_index = actor_indexes[message.to]
    local from_x = lifeline_x[from_index]
    local to_x = lifeline_x[to_index]
    local is_self = from_index == to_index
    local line_char = message.line_style == "dashed" and "╌" or H
    local arrow_char = message.arrow_head == "filled" and "▶" or "▷"
    local reverse_arrow_char = message.arrow_head == "filled" and "◀" or "◁"

    if is_self then
      local arrow_y = message_arrow_y[message_index]
      local loop_width = 4
      set_char(from_x, arrow_y, JL)
      for x = from_x + 1, from_x + loop_width - 1 do
        set_char(x, arrow_y, line_char)
      end
      set_char(from_x + loop_width, arrow_y, "┐")
      set_char(from_x + loop_width, arrow_y + 1, V)

      local message_lines = text.split_label_lines(message.label)
      for line_index, line in ipairs(message_lines) do
        canvas.draw_text(rendered, { x = from_x + loop_width + 2, y = arrow_y + line_index }, line, true)
      end

      set_char(from_x, arrow_y + #message_lines + 1, reverse_arrow_char)
      for x = from_x + 1, from_x + loop_width - 1 do
        set_char(x, arrow_y + #message_lines + 1, line_char)
      end
      set_char(from_x + loop_width, arrow_y + #message_lines + 1, "┘")
    else
      local label_y = message_label_y[message_index]
      local arrow_y = message_arrow_y[message_index]
      local left_to_right = from_x < to_x
      local middle_x = math.floor((from_x + to_x) / 2)

      for line_index, line in ipairs(text.split_label_lines(message.label)) do
        local label_start = middle_x - math.floor(text.char_len(line) / 2)
        canvas.draw_text(rendered, { x = label_start, y = label_y + line_index - 1 }, line, true)
      end

      if left_to_right then
        for x = from_x + 1, to_x - 1 do
          set_char(x, arrow_y, line_char)
        end
        set_char(to_x, arrow_y, arrow_char)
      else
        for x = to_x + 1, from_x - 1 do
          set_char(x, arrow_y, line_char)
        end
        set_char(to_x, arrow_y, reverse_arrow_char)
      end
    end
  end

  local function dashed_horizontal_char()
    return "╌"
  end

  for block_index, block in ipairs(diagram.blocks) do
    local top_y = block_start_y[block_index]
    local bottom_y = block_end_y[block_index]
    if top_y and bottom_y then
      local min_lifeline = total_width
      local max_lifeline = 0
      for message_index = block.start_index + 1, block.end_index + 1 do
        local message = diagram.messages[message_index]
        if message then
          local from_position = actor_indexes[message.from]
          local to_position = actor_indexes[message.to]
          min_lifeline = math.min(min_lifeline, lifeline_x[math.min(from_position, to_position)])
          max_lifeline = math.max(max_lifeline, lifeline_x[math.max(from_position, to_position)])
        end
      end

      local left_x = math.max(0, min_lifeline - 4)
      local right_x = math.min(total_width - 1, max_lifeline + 4)

      set_char(left_x, top_y, TL)
      for x = left_x + 1, right_x - 1 do
        set_char(x, top_y, H)
      end
      set_char(right_x, top_y, TR)

      local header_label = block.label ~= "" and string.format("%s [%s]", block.type, block.label) or block.type
      for line_index, line in ipairs(text.split_label_lines(header_label)) do
        if top_y + line_index - 1 < bottom_y then
          canvas.draw_text(rendered, { x = left_x + 1, y = top_y + line_index - 1 }, line, true)
        end
      end

      set_char(left_x, bottom_y, BL)
      for x = left_x + 1, right_x - 1 do
        set_char(x, bottom_y, H)
      end
      set_char(right_x, bottom_y, BR)

      for y = top_y + 1, bottom_y - 1 do
        set_char(left_x, y, V)
        set_char(right_x, y, V)
      end

      for divider_index, divider in ipairs(block.dividers) do
        local y = divider_y[string.format("%d:%d", block_index, divider_index)]
        if y then
          set_char(left_x, y, JL)
          for x = left_x + 1, right_x - 1 do
            set_char(x, y, dashed_horizontal_char())
          end
          set_char(right_x, y, JR)
          if divider.label ~= "" then
            canvas.draw_text(rendered, { x = left_x + 1, y = y }, string.format("[%s]", divider.label), true)
          end
        end
      end
    end
  end

  for _, note_position in ipairs(note_positions) do
    local x = note_position.x
    local y = note_position.y
    local width = note_position.width
    local height = note_position.height
    canvas.increase_size(rendered, x + width, y + height)

    set_char(x, y, TL)
    for offset = 1, width - 2 do
      set_char(x + offset, y, H)
    end
    set_char(x + width - 1, y, TR)

    for line_index, line in ipairs(note_position.lines) do
      local row = y + line_index
      set_char(x, row, V)
      set_char(x + width - 1, row, V)
      canvas.draw_text(rendered, { x = x + 2, y = row }, line, true)
    end

    local bottom_y = y + height - 1
    set_char(x, bottom_y, BL)
    for offset = 1, width - 2 do
      set_char(x + offset, bottom_y, H)
    end
    set_char(x + width - 1, bottom_y, BR)
  end

  local lines = canvas.canvas_to_lines(rendered)
  parser.append_unsupported_lines(lines, diagram.warnings)
  return lines
end

local M = {}
M.render = render
return M
