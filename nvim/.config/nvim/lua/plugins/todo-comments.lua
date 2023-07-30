require('todo-comments').setup()
vim.keymap.set('n', '<M-2>', '<cmd>TodoTelescope<CR>', { noremap = true, desc = 'Telescope find TODO' })

