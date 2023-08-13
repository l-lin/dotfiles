local g = vim.g
g.better_whitespace_filetypes_blacklist = "['dashboard']"
g.better_whitespace_guicolor = "#cc241d"
g.better_whitespace_enabled = 0
g.strip_whitespace_on_save = 1

vim.cmd [[ highlight ExtraWhitespace ctermbg=78 ]]

-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set
map("n", "<leader>ws", "<cmd>StripWhitespace<CR>", { noremap = true, desc = "Strip whitespace" })
map("n", "<leader>wt", "<cmd>ToggleWhitespace<CR>", { noremap = true, desc = "Toggle whitespace" })
