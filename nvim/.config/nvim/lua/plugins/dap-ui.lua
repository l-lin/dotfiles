require("dapui").setup()
vim.keymap.set('n', '<M-5>', '<Cmd>lua require("dapui").toggle()<CR>', { noremap = true, desc = 'Open DAP UI' })
