local UTF8_CHAR_PATTERN = "[%z\1-\127\194-\244][\128-\191]*"

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

local function utf8_chars(value)
  local chars = {}
  for char in value:gmatch(UTF8_CHAR_PATTERN) do
    chars[#chars + 1] = char
  end
  return chars
end

local function char_len(value)
  local count = 0
  for _ in value:gmatch(UTF8_CHAR_PATTERN) do
    count = count + 1
  end
  return count
end

local function starts_with(value, prefix)
  return value:sub(1, #prefix) == prefix
end

local function split_label_lines(label)
  return split_lines(label)
end

local function max_line_width(label)
  local widest = 0
  for _, line in ipairs(split_label_lines(label)) do
    widest = math.max(widest, char_len(line))
  end
  return widest
end

local function line_count(label)
  return #split_label_lines(label)
end

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

local function slugify(value)
  return value:gsub("%s+", "_"):gsub("[^%w]", "")
end

local function ltrim(value)
  return (value:gsub("^%s+", ""))
end

local function rtrim(value)
  return (value:gsub("%s+$", ""))
end

local function is_blank(value)
  return trim(value) == ""
end

local M = {}
M.UTF8_CHAR_PATTERN = UTF8_CHAR_PATTERN
M.trim = trim
M.ltrim = ltrim
M.rtrim = rtrim
M.split_lines = split_lines
M.split_label_lines = split_label_lines
M.utf8_chars = utf8_chars
M.char_len = char_len
M.max_line_width = max_line_width
M.line_count = line_count
M.normalize_br_tags = normalize_br_tags
M.slugify = slugify
M.starts_with = starts_with
M.is_blank = is_blank
return M
