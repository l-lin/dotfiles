local map = vim.keymap.set

map({ 'n', 'v' }, '<leader>rr', '<cmd>lua require("spectre").open()<CR>',
  { noremap = true, desc = 'Spectre open search and replace' })
map('v', '<leader>rw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
  { noremap = true, desc = 'Spectre open visual search and replace word' })

map('n', '<A-r>', '<cmd>lua require("spectre").open_file_search()<CR>',
  { noremap = true, desc = 'Spectre open search and replace in file (Alt+r)' })
map('n', '<leader>rf', '<cmd>lua require("spectre").open_file_search()<CR>',
  { noremap = true, desc = 'Spectre open search and replace in file' })
