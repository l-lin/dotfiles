local map = vim.api.nvim_set_keymap
map('n', '<leader>rr', '<cmd>lua require("spectre").open()<CR>',
  { noremap = true, desc = 'Spectre open search and replace' })
map('n', '<leader>rw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
  { noremap = true, desc = 'Spectre open visual search and replace word' })
map('v', '<leader>rr', '<cmd>lua require("spectre").open_visual()<CR>',
  { noremap = true, desc = 'Spectre open visual search and replace' })
map('n', '<leader>rf', '<cmd>lua require("spectre").open_file_search()<CR>',
  { noremap = true, desc = 'Spectre open search and replace in file' })
