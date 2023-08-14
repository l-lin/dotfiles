require("persistence").setup()

-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set

map("n", "<leader>ss", "<CMD>lua require('persistence').load()<CR>",
  { noremap = true, silent = true, desc = "Restore session for current directory" })
map("n", "<leader>sl", "<CMD>lua require('persistence').load({ last = true})<CR>",
  { noremap = true, silent = true, desc = "Restore last session" })
map("n", "<leader>sd", "<CMD>lua require('persistence').stop()<CR>",
  { noremap = true, silent = true, desc = "Stop persistence (session won't be saved on exit)" })
