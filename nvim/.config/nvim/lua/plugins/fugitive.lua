local map = vim.keymap.set
map('n', '<leader>gs', '<cmd>G<cr>', { noremap = true, desc = 'git status' })
map('n', '<leader>gc', '<cmd>G commit<cr>', { noremap = true, desc = 'git commit' })
map('n', '<leader>gp', '<cmd>G pull<cr>', { noremap = true, desc = 'git pull' })
map('n', '<leader>gP', '<cmd>G push<cr>', { noremap = true, desc = 'git push' })
map('n', '<leader>gF', '<cmd>G push --force-with-lease<cr>', { noremap = true, desc = 'git push --force-with-lease' })
map('n', '<leader>gb', '<cmd>G blame<cr>', { noremap = true, desc = 'git blame' })
map('n', '<leader>gl', '<cmd>0GcLog<cr>', { noremap = true, desc = 'git log' })
