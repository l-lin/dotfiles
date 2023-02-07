vim.g.better_whitespace_filetypes_blacklist = "['dashboard']"
vim.cmd [[ highlight ExtraWhitespace ctermbg=78 ]]
vim.api.nvim_set_keymap('n', '<leader>cw', ':StripWhitespace<CR>', { noremap = true, desc = 'Strip whitespace' })
vim.api.nvim_set_keymap('n', '<leader>pw', ':ToggleWhitespace<CR>', { noremap = true, desc = 'Toggle whitespace' })
vim.g.better_whitespace_enabled = 0
vim.g.strip_whitespace_on_save = 0
