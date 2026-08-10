local UTF8_CHAR_PATTERN = "[%z\1-\127\194-\244][\128-\191]*"

---Trim leading and trailing whitespace from a string.
---@param value string The string to trim.
---@return string The trimmed string.
local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

---Splits a string into lines based on newline characters.
---@param source string The string to split into lines.
---@return string[] A table of lines.
local function split_lines(source)
  local lines = {}
  for line in (source .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  return lines
end

---Splits a string into UTF-8 characters.
---@param value string The string to split into characters.
---@return string[] A table of UTF-8 characters.
local function utf8_chars(value)
  local chars = {}
  for char in value:gmatch(UTF8_CHAR_PATTERN) do
    chars[#chars + 1] = char
  end
  return chars
end

---Calculates the number of UTF-8 characters in a string.
---@param value string The string to measure.
---@return number The number of UTF-8 characters.
local function char_len(value)
  local count = 0
  for _ in value:gmatch(UTF8_CHAR_PATTERN) do
    count = count + 1
  end
  return count
end

---Checks if a string starts with a given prefix.
---@param value string The string to check.
---@param prefix string The prefix to look for.
---@return boolean True if the string starts with the prefix, false otherwise.
local function starts_with(value, prefix)
  return value:sub(1, #prefix) == prefix
end

---Calculates the maximum line width (in UTF-8 characters) of a multi-line string.
---@param label string The multi-line string to measure.
---@return number The maximum line width.
local function max_line_width(label)
  local widest = 0
  for _, line in ipairs(split_lines(label)) do
    widest = math.max(widest, char_len(line))
  end
  return widest
end

---Counts the number of lines in a multi-line string.
---@param label string The multi-line string to count lines in.
---@return number The number of lines.
local function line_count(label)
  return #split_lines(label)
end

---Normalizes a label by replacing <br> tags with newlines and removing certain HTML tags.
---Also converts Markdown-style bold, italic, and strikethrough to HTML tags.
---@param label string The label to normalize.
---@return string The normalized label.
local function normalize_br_tags(label)
  local unquoted = label
  if starts_with(unquoted, '"') and unquoted:sub(-1) == '"' then
    unquoted = unquoted:sub(2, -2)
  end

  local normalized = unquoted
    :gsub("<[Bb][Rr]%s*/?>", "\n")
    :gsub("\\n", "\n")
    :gsub("</?[Ss][Uu][Bb]%s*>", "")
    :gsub("</?[Ss][Uu][Pp]%s*>", "")
    :gsub("</?[Ss][Mm][Aa][Ll][Ll]%s*>", "")
    :gsub("</?[Mm][Aa][Rr][Kk]%s*>", "")

  normalized = normalized:gsub("%*%*(.-)%*%*", "<b>%1</b>")
  normalized = normalized:gsub("~~(.-)~~", "<s>%1</s>")
  normalized = normalized:gsub("%*(.-)%*", "<i>%1</i>")

  return normalized
end

---Slugifies a string by replacing spaces with underscores and removing non-alphanumeric characters.
---Example: "Hello World!" becomes "Hello_World".
---@param value string The string to slugify.
---@return string The slugified string.
---@return integer The length of the slugified string.
local function slugify(value)
  return value:gsub("%s+", "_"):gsub("[^%w]", "")
end

---Left-trims whitespace from a string.
---@param value string The string to trim.
---@return string The left-trimmed string.
local function ltrim(value)
  return (value:gsub("^%s+", ""))
end

---Right-trims whitespace from a string.
---@param value string The string to trim.
---@return string The right-trimmed string.
local function rtrim(value)
  return (value:gsub("%s+$", ""))
end

local M = {}
M.UTF8_CHAR_PATTERN = UTF8_CHAR_PATTERN
M.trim = trim
M.ltrim = ltrim
M.rtrim = rtrim
M.split_lines = split_lines
M.utf8_chars = utf8_chars
M.char_len = char_len
M.max_line_width = max_line_width
M.line_count = line_count
M.normalize_br_tags = normalize_br_tags
M.slugify = slugify
M.starts_with = starts_with
return M
