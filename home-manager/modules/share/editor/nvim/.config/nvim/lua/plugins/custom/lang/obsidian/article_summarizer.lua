local SUMMARY_PROMPT = "Fetch the content of the article %s, and return only the summary"
local LIGHT_SUMMARY_PROMPT = "Fetch the content of the article %s, and return only the summary in a few sentences (max 3)"

---Execute claude CLI with the given prompt
---@param light_summary boolean whether to use single line summary prompt
---@return string|nil result the output from opencode CLI, error message if any
local function summarize_url_with_claude_code(url, light_summary)
  local prompt = light_summary and LIGHT_SUMMARY_PROMPT or SUMMARY_PROMPT

  local opencode_cmd = string.format('opencode --model github-copilot/gpt-4.1 run "%s"', string.format(prompt, url))

  local handle = io.popen(opencode_cmd)
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

  if light_summary then
    -- Remove any leading or trailing whitespace for single line summaries
    response = response:gsub("^%s+", ""):gsub("%s+$", "")
  end

  return response
end

---Paste URL summary at cursor position
---@param light_summary boolean whether to use single line summary
local function paste_url(light_summary)
  local url = vim.fn.getreg("+")
  local success = pcall(require("helpers.url_parser").new, url)
  if not success then
    error("Failed to parse URL '" .. url .. "'")
  end

  local summary = summarize_url_with_claude_code(url, light_summary)

  if not summary then
    error("Failed to summarize URL '" .. url .. "'")
  end

  require("helpers.insert_text").at_current_cursor(summary)
end

local M = {}
M.paste_url = paste_url
return M
