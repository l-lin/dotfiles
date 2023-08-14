-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set
map("n", "<F46>", "<Cmd>lua require('neotest').run.run()<CR>",
  { noremap = true, desc = "Execute test (Shift+F10)" })
map("n", "<F45>", "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>",
  { noremap = true, desc = "Debug test (Shift+F9)" })

