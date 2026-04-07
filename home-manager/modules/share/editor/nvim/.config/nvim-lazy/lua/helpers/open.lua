---Extract word under cursor, stripping punctuation and brackets
---@return string word the sanitized word under cursor
local function extract_word()
  local w = vim.fn.expand("<cWORD>")
  w = w:gsub("[%(%)[%]{}<>\"']", "")
  w = w:gsub("[,%.:;!?]+$", "")
  return w
end

---Open URL or GitHub repo under cursor
---Opens YouTube URLs in Zen private window, everything else with vim.ui.open
local function smart_open()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local url = require("helpers.markdown_link_parser").extract_url_at_cursor(line, col)

  if not url then
    local word = extract_word()
    url = require("helpers.repo_parser").is_repo_pattern(word) and ("https://github.com/" .. word) or word
  end

  local success, url_parser = pcall(require("helpers.url_parser").new, url)
  if success and url_parser:is_youtube_url() then
    local escaped = vim.fn.shellescape(url)
    local zen = (vim.fn.has("mac") == 1) and "/Applications/Zen.app/Contents/MacOS/zen" or "zen"
    local cmd = string.format("%s -private-window %s", zen, escaped)
    vim.fn.system(cmd)
  else
    vim.ui.open(url)
  end
end

local M = {}
M.smart_open = smart_open
return M
