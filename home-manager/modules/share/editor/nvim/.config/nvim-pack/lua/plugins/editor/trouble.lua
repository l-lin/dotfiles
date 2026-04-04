--
-- 🚦 A pretty diagnostics, references, telescope results, quickfix and location list to help you solve all the trouble your code is causing.
--

require("trouble").setup({
  modes = {
    lsp = {
      win = { position = "right" },
    },
  },
})

local map = vim.keymap.set
map("n", "<M-3>", "<cmd>Trouble qflist toggle focus=true<cr>", { desc = "Toggle Trouble (Alt+3)" })
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
