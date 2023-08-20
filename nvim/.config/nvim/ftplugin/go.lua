local function attach_keymaps()
  local map = require("mapper").map
  local bufopts = { noremap = true }
  map("n", "<F46>", "<cmd>lua require('neotest').run.run()<cr>", bufopts, "Execute test (Shift+F10)")
  map("n", "<F45>", "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<cr>", bufopts, "Debug test (Shift+F9)")
end

attach_keymaps()
