local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_lines(source)
  local lines = {}
  for line in (source .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  return lines
end

local function strip_comment(line)
  local comment_start = line:find("%%", 1, true)
  if comment_start then
    return trim(line:sub(1, comment_start - 1))
  end
  return trim(line)
end

local function compact_blank_lines(lines)
  local compacted = {}
  local previous_blank = false

  for _, line in ipairs(lines) do
    local is_blank = trim(line) == ""
    if not (is_blank and previous_blank) then
      compacted[#compacted + 1] = line
    end
    previous_blank = is_blank
  end

  while compacted[#compacted] == "" do
    table.remove(compacted)
  end

  return compacted
end

local function split_fields(line)
  local fields = {}
  for field in line:gmatch("%S+") do
    fields[#fields + 1] = field
  end
  return fields
end

local function parse_direction_header(header, supported_kinds)
  local normalized = trim(header:gsub(";%s*$", ""))
  local fields = split_fields(normalized)
  if #fields == 0 then
    return nil, "missing diagram header"
  end

  local keyword = fields[1]
  if not supported_kinds[keyword] then
    return nil, string.format("unsupported diagram header: %s", keyword)
  end
  if #fields > 2 then
    return nil, string.format("unexpected tokens after direction: %s", table.concat(fields, " "))
  end

  local direction = fields[2] or supported_kinds[keyword]
  if direction == "TB" then
    direction = "TD"
  end
  if direction ~= "TD" and direction ~= "BT" and direction ~= "LR" and direction ~= "RL" then
    return nil, string.format("unsupported direction: %s", tostring(direction))
  end

  return direction
end

local function diagram_kind(source)
  for _, line in ipairs(split_lines(source)) do
    local header = trim(line)
    if header ~= "" then
      local kind = header:match("^(%S+)")
      if not kind then
        return nil
      end

      kind = kind:lower()
      if kind == "graph" or kind == "flowchart" then
        return "flowchart"
      end
      if kind:match("^statediagram") then
        return "state"
      end
      if kind:match("^sequencediagram") then
        return "sequence"
      end
      return nil
    end
  end

  return nil
end

local function find_mermaid_blocks(markdown_lines)
  local blocks = {}
  local current_block

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

  local unique_warnings = {}
  local seen_warnings = {}
  for _, warning in ipairs(warnings) do
    local normalized_warning = trim(warning)
    if normalized_warning ~= "" and not seen_warnings[normalized_warning] then
      seen_warnings[normalized_warning] = true
      unique_warnings[#unique_warnings + 1] = normalized_warning
    end
  end

  if #unique_warnings == 0 then
    return lines
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "[unsupported: " .. table.concat(unique_warnings, "; ") .. "]"
  return lines
end

local M = {}
M.trim = trim
M.split_lines = split_lines
M.strip_comment = strip_comment
M.compact_blank_lines = compact_blank_lines
M.parse_direction_header = parse_direction_header
M.diagram_kind = diagram_kind
M.find_mermaid_blocks = find_mermaid_blocks
M.append_unsupported_lines = append_unsupported_lines
return M
