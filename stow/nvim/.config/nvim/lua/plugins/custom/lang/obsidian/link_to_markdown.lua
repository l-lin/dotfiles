---Simple HTML title extraction using pattern matching
---@param html string the HTML content to extract the title from
---@return string|nil title the extracted title or nil if not found
local function extract_title_from_html(html)
  if html == nil or html == "" then
    return nil
  end

  -- Look for <title>...</title> tags (case insensitive)
  local title = html:match("<[tT][iI][tT][lL][eE][^>]*>([^<]*)</[tT][iI][tT][lL][eE]>")

  if title then
    -- Clean up the title (remove newlines, extra spaces)
    title = title:gsub("[\r\n]", ""):gsub("^%s*(.-)%s*$", "%1")
    return title or nil
  end

  return nil
end

---Check if content is HTML by looking for HTML tags
---@param content string the content to check
---@return boolean true if content is HTML, false otherwise
local function is_html_content(content)
  if not content then
    return false
  end

  -- Look for common HTML indicators
  local html_indicators = {
    "<html",
    "<HTML",
    "<title",
    "<TITLE",
    "<head",
    "<HEAD",
    "<body",
    "<BODY",
    "<!DOCTYPE",
    "<!doctype",
  }

  for _, indicator in ipairs(html_indicators) do
    if content:find(indicator) then
      return true
    end
  end

  return false
end

---Scrape the page title from a URL
---@param url_parser dotfiles.helpers.UrlParser the URL parser instance
---@return string|nil title the page title or the final segment of the URL
local function scrape(url_parser)
  -- Make HTTP request using curl
  local response = require("helpers.http_client").new():get(url_parser.input_url)

  if not response or response.status_code >= 400 then
    error("HTTP request failed")
  end

  -- Check if response is HTML
  if not is_html_content(response.content) then
    local final_segment = url_parser:get_url_final_segment()
    if not final_segment then
      return url_parser.input_url
    end
    return final_segment
  end

  -- Extract title
  local title = extract_title_from_html(response.content)

  if title == nil or title == "" then
    -- Fallback: check for no-title attribute (simplified)
    local no_title = response.content:match('<[tT][iI][tT][lL][eE][^>]*no%-title="([^"]*)"')
    if no_title and no_title ~= "" then
      return no_title
    end

    -- Ultimate fallback: return URL
    return url_parser.input_url
  end

  return title
end

---Get page title from URL
---@param url_parser dotfiles.helpers.UrlParser the URL parser instance
---@return string title the page title or fallback URL
local function get_page_title(url_parser)
  local success, result = pcall(scrape, url_parser)

  if success then
    return result or url_parser.input_url
  end

  -- Fallback to URL if scraping fails
  return url_parser.input_url
end

---Escape special characters for markdown (equivalent to escapeMarkdown in TypeScript)
---@param text string the text to escape
---@return string escaped_text
local function escape_markdown(text)
  if text == nil or text == "" then
    return ""
  end

  -- Unescape any backslashed characters first
  text = text:gsub("\\([%*_`~\\%[%]])", "%1")

  -- Escape markdown special characters
  text = text:gsub("([%*_`|<>~\\%[%]])", "\\%1")

  return text
end

---Create a markdown link with title
---@param url_parser dotfiles.helpers.UrlParser the URL parser instance
---@return string title markdown link with the title
local function create_markdown_link(url_parser)
  local title = get_page_title(url_parser)
  local escaped_title = escape_markdown(title)

  return string.format("[%s](%s)", escaped_title, url_parser.input_url)
end

---Calculate insert column position.
---This extracts the logic from insert_string_at_current_cursor for unit testing
---@param col number the current column position
---@param line_len number the length of the current line
---@param mode string the current mode ('n' for normal, 'i' for insert)
---@return number the calculated insert column position
local function calculate_insert_col(col, line_len, mode)
  local insert_col = col
  if mode == 'n' then
    -- In normal mode, cursor is on a character (or at position 0 on empty line)
    if line_len == 0 then
      -- Empty line: insert at the beginning
      insert_col = 0
    else
      -- Non-empty line: insert after current character, but ensure it's within bounds
      insert_col = math.min(col + 1, line_len)
    end
  else
    -- In insert mode, cursor is between characters, insert at current position
    insert_col = math.min(col, line_len)
  end
  return insert_col
end

---Insert a string at the current cursor position
---@param text string the text to insert
local function insert_string_at_current_cursor(text)
  local buf = vim.api.nvim_get_current_buf()
  table.unpack = table.unpack or unpack -- 5.1 compatibility
  local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Adjust because Lua is 1-indexed but Neovim API expects 0-indexed

  -- Get the current line to check its length
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local line_len = #line

  -- Calculate where to insert the text
  local mode = vim.fn.mode()
  local insert_col = calculate_insert_col(col, line_len, mode)

  vim.api.nvim_buf_set_text(buf, row, insert_col, row, insert_col, { text })
  vim.cmd('startinsert')
  vim.api.nvim_win_set_cursor(0, { row + 1, insert_col + #text })
end

---Paste URL as markdown link at the current cursor position
local function paste_url()
  local input = vim.fn.getreg("+")
  local title = input

  local success, url_parser = pcall(require("helpers.url_parser").new, input)
  if success then
    title = create_markdown_link(url_parser)
  end

  insert_string_at_current_cursor(title)
end

local M = {}
M.paste_url = paste_url
return M
