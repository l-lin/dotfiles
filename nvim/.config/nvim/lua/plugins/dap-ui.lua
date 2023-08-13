require("dapui").setup()

-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set
map("n", "<M-5>", "<Cmd>lua require('dapui').toggle()<CR>", { noremap = true, desc = "Open DAP UI (Alt+5)" })
map("n", "<leader>du", "<Cmd>lua require('dapui').toggle()<CR>", { noremap = true, desc = "Open DAP UI (Alt+5)" })

