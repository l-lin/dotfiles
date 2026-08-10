local canvas = require("functions.lang.mermaid.canvas")
local parser = require("functions.lang.mermaid.parser")
local sequence_parser = require("functions.lang.mermaid.sequence.parser")
local text = require("functions.lang.mermaid.text")

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
local DASHED_H = "╌"

---Creates a mapping from actor IDs to their corresponding indexes in the diagram's actors list.
---@param diagram dotfiles.mermaid.sequence.Graph
---@return table<string, number>
local function actor_index_map(diagram)
  local index_map = {}
  for index, actor in ipairs(diagram.actors) do
    index_map[actor.id] = index
  end
  return index_map
end

---@param diagram dotfiles.mermaid.sequence.Graph
---@return table<string, number>
local function zero_depths(diagram)
  local depths = {}
  for _, actor in ipairs(diagram.actors) do
    depths[actor.id] = 0
  end
  return depths
end

---@param center_x number
---@param depth number
---@return number, number
local function activation_bounds(center_x, depth)
  if depth <= 0 then
    return center_x, center_x
  end

  local left_x = center_x - 1 + ((depth - 1) * 2)
  return left_x, left_x + 2
end

---@param center_x number
---@param depth number
---@param direction "left"|"right"
---@param role "from"|"to"
---@return number
local function message_terminal_x(center_x, depth, direction, role)
  if depth <= 0 then
    return center_x
  end

  local left_x, right_x = activation_bounds(center_x, depth)
  if direction == "right" then
    return role == "from" and right_x + 1 or left_x - 1
  end
  return role == "from" and left_x - 1 or right_x + 1
end

---@param diagram dotfiles.mermaid.sequence.Graph
---@return table<string, number>
local function compute_max_activation_depths(diagram)
  local depths = zero_depths(diagram)
  local max_depths = zero_depths(diagram)

  local function record_depth(actor_id, depth)
    max_depths[actor_id] = math.max(max_depths[actor_id] or 0, depth)
  end

  for _, event in ipairs(diagram.events or {}) do
    if event.type == "message" then
      local message = diagram.messages[event.message_index]
      if message and message.activate_actor then
        depths[message.activate_actor] = (depths[message.activate_actor] or 0) + 1
        record_depth(message.activate_actor, depths[message.activate_actor])
      end
      if message and message.deactivate_actor then
        depths[message.deactivate_actor] = math.max((depths[message.deactivate_actor] or 0) - 1, 0)
      end
    elseif event.type == "activation" then
      if event.action == "activate" then
        if (depths[event.actor_id] or 0) == 0 then
          depths[event.actor_id] = 1
          record_depth(event.actor_id, 1)
        end
      elseif event.action == "deactivate" then
        depths[event.actor_id] = math.max((depths[event.actor_id] or 0) - 1, 0)
      end
    end
  end

  return max_depths
end

---@param note table
---@return string[], number, number
local function note_geometry(note)
  local note_lines = text.split_lines(note.text)
  local note_width = 4
  for _, line in ipairs(note_lines) do
    note_width = math.max(note_width, text.char_len(line) + 4)
  end
  return note_lines, note_width, #note_lines + 2
end

---@param source string
---@return string[]|nil
---@return string|nil
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

  local actor_indexes = actor_index_map(diagram)
  local max_activation_depths = compute_max_activation_depths(diagram)
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
    local previous_spill = math.max(((max_activation_depths[diagram.actors[index - 1].id] or 0) - 1) * 2, 0)
    local gap = math.max(
      half_boxes[index - 1] + half_boxes[index] + 2,
      (adjacency_widths[index - 1] or 0) + 2 + previous_spill,
      10 + previous_spill
    )
    lifeline_x[index] = lifeline_x[index - 1] + gap
  end

  local message_layouts = {}
  local note_positions = {}
  local block_start_y = {}
  local block_end_y = {}
  local divider_y = {}
  local activation_segments = {}
  local active_depths = zero_depths(diagram)
  local open_activation_starts = {}
  for _, actor in ipairs(diagram.actors) do
    open_activation_starts[actor.id] = {}
  end

  local function start_activation(actor_id, start_y, allow_nesting)
    local current_depth = active_depths[actor_id] or 0
    if not allow_nesting and current_depth > 0 then
      return
    end

    local next_depth = current_depth + 1
    active_depths[actor_id] = next_depth
    open_activation_starts[actor_id][next_depth] = start_y
  end

  local function end_activation(actor_id, end_y)
    local current_depth = active_depths[actor_id] or 0
    if current_depth <= 0 then
      return
    end

    activation_segments[#activation_segments + 1] = {
      actor_id = actor_id,
      depth = current_depth,
      start_y = open_activation_starts[actor_id][current_depth],
      end_y = end_y,
    }
    open_activation_starts[actor_id][current_depth] = nil
    active_depths[actor_id] = current_depth - 1
  end

  local cursor_y = actor_box_height

  for _, event in ipairs(diagram.events or {}) do
    if event.type == "block_start" then
      cursor_y = cursor_y + 2
      block_start_y[event.block] = cursor_y - 1
    elseif event.type == "block_divider" then
      cursor_y = cursor_y + 1
      divider_y[event.divider] = cursor_y
      cursor_y = cursor_y + 1
    elseif event.type == "message" then
      local message = diagram.messages[event.message_index]
      local from_index = actor_indexes[message.from]
      local to_index = actor_indexes[message.to]
      local is_self = from_index == to_index
      local message_line_count = text.line_count(message.label)
      local from_depth_before = active_depths[message.from] or 0
      local to_depth_before = active_depths[message.to] or 0

      cursor_y = cursor_y + 1

      if is_self then
        local arrow_y = cursor_y
        local label_y = cursor_y + 1
        local target_depth = from_depth_before
        if message.activate_actor == message.from then
          target_depth = from_depth_before + 1
        end

        local current_terminal = message_terminal_x(lifeline_x[from_index], from_depth_before, "right", "from")
        local target_terminal = message_terminal_x(lifeline_x[to_index], target_depth, "right", "to")
        local loop_start_x = from_depth_before > 0 and current_terminal + 1 or current_terminal
        local right_edge = math.max(loop_start_x + 4, target_terminal + 2)

        message_layouts[event.message_index] = {
          arrow_y = arrow_y,
          label_y = label_y,
          from_index = from_index,
          to_index = to_index,
          is_self = true,
          from_depth_before = from_depth_before,
          target_depth = target_depth,
          start_x = loop_start_x,
          right_edge = right_edge,
        }

        cursor_y = cursor_y + 2 + message_line_count
      else
        local label_y = cursor_y
        local arrow_y = cursor_y + message_line_count
        local left_to_right = lifeline_x[from_index] < lifeline_x[to_index]
        local target_depth = to_depth_before
        if message.activate_actor == message.to then
          target_depth = to_depth_before + 1
        end

        local direction = left_to_right and "right" or "left"
        local from_terminal = message_terminal_x(lifeline_x[from_index], from_depth_before, direction, "from")
        local to_terminal = message_terminal_x(lifeline_x[to_index], target_depth, direction, "to")

        message_layouts[event.message_index] = {
          arrow_y = arrow_y,
          label_y = label_y,
          from_index = from_index,
          to_index = to_index,
          is_self = false,
          from_depth_before = from_depth_before,
          target_depth = target_depth,
          left_to_right = left_to_right,
          from_x = from_terminal,
          to_x = to_terminal,
        }

        cursor_y = cursor_y + message_line_count + 1
      end

      if message.activate_actor then
        local start_y = message_layouts[event.message_index].arrow_y + 1
        start_activation(message.activate_actor, start_y, true)
      end
      if message.deactivate_actor then
        end_activation(message.deactivate_actor, cursor_y)
      end
    elseif event.type == "note" then
      local note = diagram.notes[event.note_index]
      local note_lines, note_width, note_height = note_geometry(note)
      local actor_position = actor_indexes[note.actor_ids[1]] or 1
      local actor_center = lifeline_x[actor_position]
      local actor_depth = active_depths[note.actor_ids[1]] or 0
      local actor_left, actor_right = activation_bounds(actor_center, actor_depth)

      cursor_y = cursor_y + 1

      local note_x
      if note.position == "left" then
        note_x = actor_left - note_width - 1
      elseif note.position == "right" then
        note_x = actor_right + 2
      else
        local left_bound = actor_left
        local right_bound = actor_right
        if #note.actor_ids >= 2 then
          local second_position = actor_indexes[note.actor_ids[2]] or actor_position
          local second_center = lifeline_x[second_position]
          local second_depth = active_depths[note.actor_ids[2]] or 0
          local second_left, second_right = activation_bounds(second_center, second_depth)
          left_bound = math.min(left_bound, second_left)
          right_bound = math.max(right_bound, second_right)
        end
        note_x = math.floor((left_bound + right_bound) / 2) - math.floor(note_width / 2)
      end

      note_positions[#note_positions + 1] = {
        x = math.max(0, note_x),
        y = cursor_y,
        width = note_width,
        height = note_height,
        lines = note_lines,
      }
      cursor_y = cursor_y + note_height
    elseif event.type == "activation" then
      if event.action == "activate" then
        start_activation(event.actor_id, cursor_y, false)
      elseif event.action == "deactivate" then
        end_activation(event.actor_id, cursor_y)
      end
    elseif event.type == "block_end" then
      cursor_y = cursor_y + 1
      block_end_y[event.block] = cursor_y
      cursor_y = cursor_y + 1
    end
  end

  cursor_y = cursor_y + 1
  local footer_y = cursor_y

  for _, actor in ipairs(diagram.actors) do
    while (active_depths[actor.id] or 0) > 0 do
      end_activation(actor.id, footer_y - 1)
    end
  end

  local total_height = footer_y + actor_box_height
  local last_lifeline = lifeline_x[#lifeline_x] or 0
  local last_half_box = half_boxes[#half_boxes] or 0
  local total_width = last_lifeline + last_half_box + 2

  for _, segment in ipairs(activation_segments) do
    local actor_index = actor_indexes[segment.actor_id]
    local _, right_x = activation_bounds(lifeline_x[actor_index], segment.depth)
    total_width = math.max(total_width, right_x + 2)
  end

  for _, layout in pairs(message_layouts) do
    if layout.is_self then
      total_width = math.max(total_width, layout.right_edge + 1 + text.max_line_width(diagram.messages[_].label))
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
    local lines = text.split_lines(label)
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

  local function draw_activation(segment)
    local actor_index = actor_indexes[segment.actor_id]
    local left_x, right_x = activation_bounds(lifeline_x[actor_index], segment.depth)
    local top_y = segment.start_y
    local bottom_y = math.max(segment.end_y, top_y + 1)

    set_char(left_x, top_y, TL)
    set_char(left_x + 1, top_y, H)
    set_char(right_x, top_y, TR)

    for y = top_y + 1, bottom_y - 1 do
      set_char(left_x, y, V)
      set_char(left_x + 1, y, " ")
      set_char(right_x, y, V)
    end

    set_char(left_x, bottom_y, BL)
    set_char(left_x + 1, bottom_y, H)
    set_char(right_x, bottom_y, BR)
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

  for _, block in ipairs(diagram.blocks) do
    local top_y = block_start_y[block]
    local bottom_y = block_end_y[block]
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
      local header_label = block.label ~= "" and string.format("%s [%s]", block.type, block.label) or block.type

      set_char(left_x, top_y, TL)
      for x = left_x + 1, right_x - 1 do
        set_char(x, top_y, H)
      end
      set_char(right_x, top_y, TR)

      for line_index, line in ipairs(text.split_lines(header_label)) do
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

      for _, divider in ipairs(block.dividers) do
        local y = divider_y[divider]
        if y then
          set_char(left_x, y, JL)
          for x = left_x + 1, right_x - 1 do
            set_char(x, y, DASHED_H)
          end
          set_char(right_x, y, JR)
          if divider.label ~= "" then
            canvas.draw_text(rendered, { x = left_x + 1, y = y }, string.format("[%s]", divider.label), true)
          end
        end
      end
    end
  end

  table.sort(activation_segments, function(left, right)
    if left.start_y == right.start_y then
      return left.depth < right.depth
    end
    return left.start_y < right.start_y
  end)
  for _, segment in ipairs(activation_segments) do
    draw_activation(segment)
  end

  for message_index, message in ipairs(diagram.messages) do
    local layout = message_layouts[message_index]
    local line_char = message.line_style == "dashed" and DASHED_H or H
    local arrow_char = message.arrow_head == "filled" and "▶" or "▷"
    local reverse_arrow_char = message.arrow_head == "filled" and "◀" or "◁"

    if layout.is_self then
      local message_lines = text.split_lines(message.label)
      set_char(layout.start_x, layout.arrow_y, JL)
      for x = layout.start_x + 1, layout.right_edge - 1 do
        set_char(x, layout.arrow_y, line_char)
      end
      set_char(layout.right_edge, layout.arrow_y, TR)
      set_char(layout.right_edge, layout.arrow_y + 1, V)

      for line_index, line in ipairs(message_lines) do
        canvas.draw_text(rendered, { x = layout.right_edge + 2, y = layout.arrow_y + line_index }, line, true)
      end

      set_char(layout.start_x, layout.arrow_y + #message_lines + 1, reverse_arrow_char)
      for x = layout.start_x + 1, layout.right_edge - 1 do
        set_char(x, layout.arrow_y + #message_lines + 1, line_char)
      end
      set_char(layout.right_edge, layout.arrow_y + #message_lines + 1, BR)
    else
      local middle_x = math.floor((layout.from_x + layout.to_x) / 2)
      for line_index, line in ipairs(text.split_lines(message.label)) do
        local label_start = middle_x - math.floor(text.char_len(line) / 2)
        canvas.draw_text(rendered, { x = label_start, y = layout.label_y + line_index - 1 }, line, true)
      end

      if layout.left_to_right then
        for x = layout.from_x + 1, layout.to_x - 1 do
          set_char(x, layout.arrow_y, line_char)
        end
        set_char(layout.to_x, layout.arrow_y, arrow_char)
      else
        for x = layout.to_x + 1, layout.from_x - 1 do
          set_char(x, layout.arrow_y, line_char)
        end
        set_char(layout.to_x, layout.arrow_y, reverse_arrow_char)
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
