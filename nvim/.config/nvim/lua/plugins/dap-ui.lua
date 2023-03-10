require("dapui").setup()
vim.api.nvim_set_keymap('n', '<M-5>', '<Cmd>lua require("dapui").toggle()<CR>', { noremap = true, desc = 'Open DAP UI' })
