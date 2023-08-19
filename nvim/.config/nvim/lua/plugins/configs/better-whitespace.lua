local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }
  map("n", "<leader>ws", "<cmd>StripWhitespace<CR>", bufopts, "Strip whitespace")
  map("n", "<leader>wt", "<cmd>ToggleWhitespace<CR>", bufopts, "Toggle whitespace")
end

M.setup = function()
  local g = vim.g
  g.better_whitespace_filetypes_blacklist = "['dashboard']"
  g.better_whitespace_guicolor = "#cc241d"
  g.better_whitespace_enabled = 0
  g.strip_whitespace_on_save = 1

  vim.cmd [[ highlight ExtraWhitespace ctermbg=78 ]]

  M.attach_keymaps()
end

return M
