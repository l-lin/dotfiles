local M = {}

M.setup = function()
  local g = vim.g
  g.better_whitespace_filetypes_blacklist = "['dashboard']"
  g.better_whitespace_guicolor = "#cc241d"
  g.better_whitespace_enabled = 0
  g.strip_whitespace_on_save = 1

  vim.cmd [[ highlight ExtraWhitespace ctermbg=78 ]]
end

return M
