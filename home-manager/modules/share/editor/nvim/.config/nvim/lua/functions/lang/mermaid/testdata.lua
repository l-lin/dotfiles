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

local function normalize_whitespace(value)
  local lines = split_lines(value)
  local normalized = {}

  for _, line in ipairs(lines) do
    normalized[#normalized + 1] = line:gsub("%s+$", "")
  end

  while normalized[1] == "" do
    table.remove(normalized, 1)
  end
  while normalized[#normalized] == "" do
    table.remove(normalized, #normalized)
  end

  return table.concat(normalized, "\n")
end

local function parse_golden(content)
  local lines = split_lines(content)
  local mermaid_lines = {}
  local expected_lines = {}
  local padding_x = 5
  local padding_y = 5
  local in_mermaid = true
  local mermaid_started = false

  for _, line in ipairs(lines) do
    if line == "---" then
      in_mermaid = false
    elseif in_mermaid then
      local normalized = trim(line)
      if not mermaid_started then
        if normalized == "" then
          goto continue
        end

        local axis, raw_value = normalized:match("^padding([xyXY])%s*=%s*(%d+)%s*$")
        if axis and raw_value then
          local value = tonumber(raw_value)
          if axis:lower() == "x" then
            padding_x = value
          else
            padding_y = value
          end
          goto continue
        end
      end

      mermaid_started = true
      mermaid_lines[#mermaid_lines + 1] = line
    else
      expected_lines[#expected_lines + 1] = line
    end

    ::continue::
  end

  return {
    mermaid = table.concat(mermaid_lines, "\n") .. "\n",
    expected = table.concat(expected_lines, "\n"),
    padding_x = padding_x,
    padding_y = padding_y,
  }
end

local function load_golden(relative_name)
  local helper_path = debug.getinfo(1, "S").source:sub(2)
  local fixture_path = helper_path:match("^(.*)/[^/]+$") .. "/testdata/unicode/" .. relative_name .. ".txt"
  local handle = assert(io.open(fixture_path, "r"))
  local content = handle:read("*a")
  handle:close()
  return parse_golden(content)
end

local M = {}
M.normalize_whitespace = normalize_whitespace
M.load_golden = load_golden
return M
