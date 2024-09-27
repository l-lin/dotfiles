---Get the text selected in visual mode, to be used for example in the Telescope opts `default_text`.
---@return string: the selected text from visual mode
local function get_selected_text()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", {})
  text = string.gsub(text, "\n", "")
  if string.len(text) == 0 then
    text = ""
  end
  return text
end

local function find_associate_test_or_file()
  local default_text = ""
  local filename = vim.fn.expand("%:t")
  local name, extension = filename:match("(.+)%.(.+)")
  if name:sub(-#"_test") == "_test" then
    default_text = name:gsub("_test", "") .. "." .. extension
  else
    default_text = name .. "_test." .. extension
  end
  return default_text
end

local M = {}

M.get_selected_text = get_selected_text
M.find_associate_test_or_file = find_associate_test_or_file

return M
