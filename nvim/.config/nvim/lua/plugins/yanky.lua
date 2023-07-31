local mapping = require("yanky.telescope.mapping")
local map = vim.keymap.set

require('yanky').setup({
  ring = {
    history_length = 10
  },
  highlight = {
    timer = 300,
  },
  picker = {
    telescope = {
      use_default_mappings = false,
      mappings = {
        default = mapping.put('p')
      }
    }
  }
})

map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
map({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
map({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
map("n", "<c-n>", "<Plug>(YankyCycleForward)")
map("n", "<c-p>", "<Plug>(YankyCycleBackward)")
