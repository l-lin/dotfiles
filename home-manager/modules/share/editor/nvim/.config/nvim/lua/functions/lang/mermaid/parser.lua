local text = require("functions.lang.mermaid.text")

---Preprocesses the source by trimming whitespace, removing empty lines,
---and ignoring comment lines starting with "%%".
---@param source string The raw source code of the Mermaid diagram.
---@return string[] A list of preprocessed lines.
local function preprocess_source(source)
  local lines = {}
  for _, raw_line in ipairs(text.split_lines(source)) do
    local normalized = text.trim(raw_line)
    if normalized ~= "" and normalized:sub(1, 2) ~= "%%" then
      lines[#lines + 1] = normalized
    end
  end
  return lines
end

---Determines the kind of Mermaid diagram based on the first non-empty line.
---@param source string The raw source code of the Mermaid diagram.
---@return string|nil The kind of diagram ("flowchart", "state", "sequence")
local function diagram_kind(source)
  for _, raw_line in ipairs(text.split_lines(source)) do
    local header = text.trim(raw_line)
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

---Finds all Mermaid code blocks in a list of Markdown lines.
---@param markdown_lines string[] A list of lines from a Markdown document.
---@return table[] A list of Mermaid code blocks, each containing start_row, end_row,
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

---Appends unsupported warnings to the list of lines, if any.
---@param lines string[] The list of lines to append to.
---@param warnings string[] A list of unsupported warnings.
---@return string[] The updated list of lines with warnings appended.
local function append_unsupported_lines(lines, warnings)
  if not warnings or #warnings == 0 then
    return lines
  end

  local seen = {}
  local rendered_warnings = {}

  for _, warning in ipairs(warnings) do
    local normalized = text.trim(warning)
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

---Adds a warning message to the graph's warnings list.
---@param graph table The graph object containing a warnings list.
---@param raw_line string The warning message to add.
local function add_warning(graph, raw_line)
  graph.warnings[#graph.warnings + 1] = text.trim(raw_line)
end

---Parses a string of style properties into a key-value table.
---@param props_string string The string containing style properties (e.g., "color: red;
local function parse_style_props(props_string)
  local cleaned = props_string:gsub(";%s*$", "")
  local props = {}

  for pair in cleaned:gmatch("[^,]+") do
    local colon_index = pair:find(":", 1, true)
    if colon_index and colon_index > 1 then
      local key = text.trim(pair:sub(1, colon_index - 1))
      local value = text.trim(pair:sub(colon_index + 1))
      if key ~= "" and value ~= "" then
        props[key] = value
      end
    end
  end

  return props
end

local M = {}
M.diagram_kind = diagram_kind
M.find_mermaid_blocks = find_mermaid_blocks
M.append_unsupported_lines = append_unsupported_lines
M.preprocess_source = preprocess_source
M.add_warning = add_warning
M.parse_style_props = parse_style_props
return M
