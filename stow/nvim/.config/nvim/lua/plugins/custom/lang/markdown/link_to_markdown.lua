local USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

---Check if the input is a valid URL
---@param input_url string the URL to check
---@return boolean true if the input is a valid URL, false otherwise
local function is_valid_url(input_url)
  return input_url and input_url:match("^https?://[%w%.%-]+") ~= nil
end

---Parse URL into components
---@param input_url string the URL to parse
---@return table|nil a table with protocol, host, port, and path or nil if parsing fails
local function parse_url(input_url)
  local protocol, host, port, path = input_url:match("^(https?)://([^:/]+):?(%d*)(.*)$")
  if not protocol then
    return nil
  end

  port = port ~= "" and tonumber(port) or (protocol == "https" and 443 or 80)
  path = path ~= "" and path or "/"

  return {
    protocol = protocol,
    host = host,
    port = port,
    path = path,
  }
end

---Extract the final segment from a URL path (for non-HTML content)
---@param input_url string the URL to extract the final segment from
---@return string the final segment of the URL path or "File" if not found
local function get_url_final_segment(input_url)
  local parsed = parse_url(input_url)
  if not parsed or not parsed.path then
    return "File"
  end

  local segments = {}
  for segment in parsed.path:gmatch("[^/]+") do
    table.insert(segments, segment)
  end

  if #segments > 0 then
    return segments[#segments]
  else
    return "File"
  end
end

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

---Simple HTTP GET request using curl command
---@param input_url string the URL to fetch
---@return string|nil, string|nil response the response body or nil if an error occurred
local function http_get(input_url)
  -- Use curl to fetch the URL
  local curl_cmd = string.format('curl -s -L -H "User-Agent: %s" "%s"', USER_AGENT, input_url)
  local handle = io.popen(curl_cmd)

  if not handle then
    return nil, "Failed to execute curl command"
  end

  local response = handle:read("*a")
  local success = handle:close()

  if not success then
    return nil, "Curl command failed"
  end

  return response, nil
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
---@param input_url string the URL to scrape
---@return string|nil title the page title or the final segment of the URL
local function scrape(input_url)
  -- Make HTTP request using curl
  local response, error_msg = http_get(input_url)

  if not response then
    error("HTTP request failed: " .. tostring(error_msg))
  end

  -- Check if response is HTML
  if not is_html_content(response) then
    return get_url_final_segment(input_url)
  end

  -- Extract title
  local title = extract_title_from_html(response)

  if title == nil or title == "" then
    -- Fallback: check for no-title attribute (simplified)
    local no_title = response:match('<[tT][iI][tT][lL][eE][^>]*no%-title="([^"]*)"')
    if no_title and no_title ~= "" then
      return no_title
    end

    -- Ultimate fallback: return URL
    return input_url
  end

  return title
end

---Get page title from URL
---@param input_url string the URL to fetch the title from
---@return string|nil title the page title or an error message
local function get_page_title(input_url)
  local success, result = pcall(scrape, input_url)

  if success then
    return result
  end

  error("Error fetching title: " .. tostring(result))
  return "Error fetching title"
end

---Escape special characters for markdown (equivalent to escapeMarkdown in TypeScript)
---@parm text string the text to escape
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
---@param input_url string the URL to fetch the title from
---@return string title markdown link with the title
local function create_markdown_link(input_url)
  local title = get_page_title(input_url)
  local escaped_title = escape_markdown(title)

  return string.format("[%s](%s)", escaped_title, input_url)
end

---Paste URL as markdown link at the current cursor position
local function paste_url()
  local input = vim.fn.getreg("+")
  local title = input
  if is_valid_url(input) then
    title = create_markdown_link(input)
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { title })
end

local M = {}
M.is_url = is_valid_url
M.create_markdown_link = create_markdown_link
M.paste_url = paste_url
return M
