-- get neotest namespace (api call creates or returns namespace)
local neotest_ns = vim.api.nvim_create_namespace("neotest")

vim.diagnostic.config({
  virtual_text = {
    format = function(diagnostic)
      local message =
          diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
      return message
    end,
  },
}, neotest_ns)

require("neotest").setup({
  -- your neotest config here
  adapters = {
    require("neotest-go"),
  },
})

-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set
map("n", "<F46>", "<Cmd>lua require('neotest').run.run()<CR>",
  { noremap = true, desc = "Execute test (Shift+F10)" })
map("n", "<F45>", "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>",
  { noremap = true, desc = "Debug test (Shift+F9)" })

