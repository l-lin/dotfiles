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

local _last_picker = nil
---Resume Telescope search if picker is the same.
-- src: https://github.com/nvim-telescope/telescope.nvim/issues/1701#issuecomment-1817992007
---@param func function: the Telescope picker
---@param opts table: options to pass to the picker
local function resume_search_if_same_picker(func, opts)
  if func == _last_picker then
    require("telescope.builtin").resume()
  else
    _last_picker = func
    func(opts or {})
  end
end

local M = {}

M.get_selected_text = get_selected_text
M.resume_search_if_same_picker = resume_search_if_same_picker

return M
