local map = vim.api.nvim_set_keymap

map('n', '<C-n>', ':Telescope find_files find_command=rg,--no-ignore,--hidden,--glob=!.git/,--files prompt_prefix=🔍<CR>', { noremap = true, silent = true, desc = 'Find file' })
map('n', '<C-g>', ':Telescope live_grep<CR>', { noremap = true, desc = 'Find pattern in all files' })
