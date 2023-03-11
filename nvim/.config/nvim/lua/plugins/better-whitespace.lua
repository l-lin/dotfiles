vim.g.better_whitespace_filetypes_blacklist = "['dashboard']"
vim.cmd [[ highlight ExtraWhitespace ctermbg=78 ]]
vim.api.nvim_set_keymap('n', '<leader>cw', '<cmd>StripWhitespace<CR>', { noremap = true, desc = 'Strip whitespace' })
vim.api.nvim_set_keymap('n', '<leader>cW', '<cmd>ToggleWhitespace<CR>', { noremap = true, desc = 'Toggle whitespace' })
vim.g.better_whitespace_guicolor = '#cc241d'
vim.g.better_whitespace_enabled = 0
vim.g.strip_whitespace_on_save = 1
