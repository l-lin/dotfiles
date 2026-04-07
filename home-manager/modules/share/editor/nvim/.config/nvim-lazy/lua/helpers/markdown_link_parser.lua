---Extract markdown link URL from a line at a given column position
---@param line string the line containing potential markdown link
---@param col number the column position (1-indexed)
---@return string|nil url the URL if cursor is on a markdown link, nil otherwise
local function extract_url_at_cursor(line, col)
  for link_start, text, url, link_end in line:gmatch("()%[([^%]]+)%]%(([^%)]+)%)()") do
    if col >= link_start and col < link_end then
      return url
    end
  end
  return nil
end

local M = {}
M.extract_url_at_cursor = extract_url_at_cursor
return M
