local text = require("functions.lang.mermaid.text")

local MESSAGE_OPERATORS = {
  "-->>",
  "->>",
  "--)",
  "-)",
  "--x",
  "-x",
  "-->",
  "->",
}

local BLOCK_TYPES = {
  loop = true,
  alt = true,
  opt = true,
  par = true,
  critical = true,
  break_ = true,
  rect = true,
}

---Escapes special characters in a string for use in Lua patterns.
---@param value string The string to escape.
---@return string The escaped string.
local function escape_pattern(value)
  return (value:gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1"))
end

---Preprocesses the source string by splitting it into lines, trimming
---whitespace, and removing comments.
---@param source string The source string to preprocess.
---@return string[] A table of preprocessed lines.
local function preprocess_sequence_source(source)
  local lines = {}
  for _, raw_line in ipairs(text.split_lines(source)) do
    local normalized = text.trim(raw_line)
    if normalized ~= "" and normalized:sub(1, 2) ~= "%%" then
      lines[#lines + 1] = normalized
    end
  end
  return lines
end

---Ensures that an actor with the given ID exists in the diagram.
---If the actor does not exist, it is added to the diagram's actors list.
---@param diagram table The diagram table containing actors and actor_ids.
---@param actor_id string The ID of the actor to ensure exists.
local function ensure_actor(diagram, actor_id)
  if not diagram.actor_ids[actor_id] then
    diagram.actor_ids[actor_id] = true
    diagram.actors[#diagram.actors + 1] = {
      id = actor_id,
      label = actor_id,
      type = "participant",
    }
  end
end

---Parses a Mermaid sequence diagram source string into a structured 
---representation.
---@param source string The Mermaid sequence diagram source string.
---@return dotfiles.mermaid.sequence.Graph|nil The parsed diagram structure, or nil if parsing failed.
---@return string|nil An error message if parsing failed, or nil if successful.
local function parse(source)
  local lines = preprocess_sequence_source(source)
  if #lines == 0 then
    return nil, "Empty mermaid diagram"
  end
  if lines[1] ~= "sequenceDiagram" then
    return nil, "unsupported diagram kind"
  end

  ---@type dotfiles.mermaid.sequence.Graph
  local diagram = {
    actors = {},
    actor_ids = {},
    messages = {},
    blocks = {},
    notes = {},
    events = {},
    warnings = {},
  }

  local block_stack = {}

  for index = 2, #lines do
    local line = lines[index]

    local keyword, rest = line:match("^(%S+)%s+(.+)$")
    if keyword == "participant" or keyword == "actor" then
      local actor_id, raw_actor_label = rest:match("^([^%s]+)%s+as%s+(.+)$")
      if actor_id and raw_actor_label then
        if not diagram.actor_ids[actor_id] then
          diagram.actor_ids[actor_id] = true
          diagram.actors[#diagram.actors + 1] = {
            id = actor_id,
            label = text.normalize_br_tags(text.trim(raw_actor_label)),
            type = keyword,
          }
        end
        goto continue
      end

      actor_id = rest:match("^([^%s]+)$")
      if actor_id then
        if not diagram.actor_ids[actor_id] then
          diagram.actor_ids[actor_id] = true
          diagram.actors[#diagram.actors + 1] = {
            id = actor_id,
            label = actor_id,
            type = keyword,
          }
        end
        goto continue
      end
    end

    local note_rest = line:match("^[Nn]ote%s+(.+)$")
    if note_rest then
      local note_position, note_actors, raw_note_text = nil, nil, nil
      if note_rest:match("^left of%s+") then
        note_position = "left"
        note_actors, raw_note_text = note_rest:match("^left of%s+([^:]+):%s*(.+)$")
      elseif note_rest:match("^right of%s+") then
        note_position = "right"
        note_actors, raw_note_text = note_rest:match("^right of%s+([^:]+):%s*(.+)$")
      elseif note_rest:match("^over%s+") then
        note_position = "over"
        note_actors, raw_note_text = note_rest:match("^over%s+([^:]+):%s*(.+)$")
      end

      if note_position and note_actors and raw_note_text then
        local actor_ids = {}
        for actor_name in note_actors:gmatch("[^,]+") do
          local normalized_actor_id = text.trim(actor_name)
          ensure_actor(diagram, normalized_actor_id)
          actor_ids[#actor_ids + 1] = normalized_actor_id
        end

        diagram.notes[#diagram.notes + 1] = {
          actor_ids = actor_ids,
          text = text.normalize_br_tags(text.trim(raw_note_text)),
          position = note_position,
          after_index = #diagram.messages - 1,
        }
        diagram.events[#diagram.events + 1] = {
          type = "note",
          note_index = #diagram.notes,
        }
        goto continue
      end
    end

    local activation_actor_id = line:match("^activate%s+([^%s]+)%s*$")
    if activation_actor_id then
      ensure_actor(diagram, activation_actor_id)
      diagram.events[#diagram.events + 1] = {
        type = "activation",
        action = "activate",
        actor_id = activation_actor_id,
      }
      goto continue
    end

    local deactivation_actor_id = line:match("^deactivate%s+([^%s]+)%s*$")
    if deactivation_actor_id then
      ensure_actor(diagram, deactivation_actor_id)
      diagram.events[#diagram.events + 1] = {
        type = "activation",
        action = "deactivate",
        actor_id = deactivation_actor_id,
      }
      goto continue
    end

    local block_keyword, block_label = line:match("^(%S+)%s*(.*)$")
    if block_keyword then
      local normalized_keyword = block_keyword == "break" and "break_" or block_keyword
      if BLOCK_TYPES[normalized_keyword] then
        local block = {
          type = block_keyword,
          label = text.normalize_br_tags(text.trim(block_label or "")),
          start_index = #diagram.messages,
          dividers = {},
        }
        block_stack[#block_stack + 1] = block
        diagram.events[#diagram.events + 1] = {
          type = "block_start",
          block = block,
        }
        goto continue
      end
    end

    local divider_keyword, divider_label = line:match("^(%S+)%s*(.*)$")
    if (divider_keyword == "else" or divider_keyword == "and") and #block_stack > 0 then
      local current_block = block_stack[#block_stack]
      current_block.dividers[#current_block.dividers + 1] = {
        index = #diagram.messages,
        label = text.normalize_br_tags(text.trim(divider_label or "")),
      }
      diagram.events[#diagram.events + 1] = {
        type = "block_divider",
        block = current_block,
        divider = current_block.dividers[#current_block.dividers],
      }
      goto continue
    end

    if line == "end" and #block_stack > 0 then
      local completed = table.remove(block_stack)
      completed.end_index = math.max(#diagram.messages - 1, completed.start_index)
      diagram.blocks[#diagram.blocks + 1] = completed
      diagram.events[#diagram.events + 1] = {
        type = "block_end",
        block = completed,
      }
      goto continue
    end

    local raw_head, raw_message_label = line:match("^(.-)%s*:%s*(.+)$")
    if raw_head and raw_message_label then
      local from_actor_id, activation_mark, to_actor_id, matched_operator = nil, nil, nil, nil
      for _, operator in ipairs(MESSAGE_OPERATORS) do
        local escaped_operator = escape_pattern(operator)
        local candidate_from, candidate_activation, candidate_to = raw_head:match(
          "^([^%s]+)%s*" .. escaped_operator .. "%s*([+-]?)([^%s]+)%s*$"
        )
        if candidate_from and candidate_to then
          from_actor_id = candidate_from
          activation_mark = candidate_activation
          to_actor_id = candidate_to
          matched_operator = operator
          break
        end
      end

      if from_actor_id and to_actor_id and matched_operator then
        ensure_actor(diagram, from_actor_id)
        ensure_actor(diagram, to_actor_id)

        local line_style = matched_operator:sub(1, 2) == "--" and "dashed" or "solid"
        local arrow_head = (matched_operator:find(">>", 1, true) or matched_operator:find("x", 1, true)) and "filled" or "open"
        local message = {
          from = from_actor_id,
          to = to_actor_id,
          label = text.normalize_br_tags(text.trim(raw_message_label)),
          line_style = line_style,
          arrow_head = arrow_head,
        }
        if activation_mark == "+" then
          message.activate = true
          message.activate_actor = to_actor_id
        elseif activation_mark == "-" then
          message.deactivate = true
          message.deactivate_actor = from_actor_id
        end
        diagram.messages[#diagram.messages + 1] = message
        diagram.events[#diagram.events + 1] = {
          type = "message",
          message_index = #diagram.messages,
        }
        goto continue
      end
    end

    diagram.warnings[#diagram.warnings + 1] = line

    ::continue::
  end

  return diagram
end

local M = {}
M.parse = parse
return M
