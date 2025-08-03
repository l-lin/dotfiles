local SUMMARY_PROMPT = "Fetch the content of the article %s, and return only the summary in a few sentences (max 3)"

---Execute claude CLI with the given prompt
---@param prompt string the prompt to send to claude
---@return string|nil result the output from claude CLI, error message if any
local function call_claude_cli(prompt)
  local claude_cmd = string.format('claude -p "%s"', prompt)

  local handle = io.popen(claude_cmd)
  if not handle then
    return nil
  end

  local response = handle:read("*a")
  local success = handle:close()

  if not success then
    return nil
  end

  if not response or response:match("^%s*$") then
    return nil
  end

  response = response:gsub("^%s+", ""):gsub("%s+$", "")

  return response
end

---Summarize the content of a URL using claude CLI
---@param url string the URL to summarize
---@return string|nil summary the summary of the URL content, error message if any
local function summarize_url(url)
  return call_claude_cli(string.format(SUMMARY_PROMPT, url))
end

---Paste URL summary at cursor position
local function paste_url()
  local url = vim.fn.getreg("+")
  local success = pcall(require("helpers.url_parser").new, url)
  if not success then
    error("Failed to parse URL '" .. url .. "'")
  end

  local summary = summarize_url(url)

  if not summary then
    error("Failed to summarize URL '" .. url .. "'")
  end

  require("helpers.insert_text").at_current_cursor(summary)
end

local M = {}
M.paste_url = paste_url
return M
