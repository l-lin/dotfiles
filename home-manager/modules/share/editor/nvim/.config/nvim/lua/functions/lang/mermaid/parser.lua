local text = require("functions.lang.mermaid.text")

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

---Preprocesses the source by trimming whitespace, removing empty lines,
---and ignoring comment lines starting with "%%".
---@param source string The raw source code of the Mermaid diagram.
---@return string[] A list of preprocessed lines.
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

local M = {}
M.trim = trim
M.split_lines = split_lines
M.compact_blank_lines = compact_blank_lines
M.diagram_kind = diagram_kind
M.find_mermaid_blocks = find_mermaid_blocks
M.append_unsupported_lines = append_unsupported_lines
M.preprocess_source = preprocess_source
M.add_warning = add_warning
M.parse_style_props = parse_style_props
return M
