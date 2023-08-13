require("flash").setup({
  search = {
    mode = "search",
  },
  label = {
    rainbow = {
      enabled = true,
    }
  }
})

-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set

map({ "n", "x", "o" }, "s", require("flash").jump, { noremap = true, silent = true, desc = "Flash" })
map({ "n", "x", "o" }, "<leader>nf", require("flash").jump, { noremap = true, silent = true, desc = "Flash (or use s)" })
map({ "n", "o", "x" }, "S", require("flash").treesitter, { noremap = true, silent = true, desc = "Flash treesitter" })
map({ "n", "o", "x" }, "<leader>nt", require("flash").treesitter,
  { noremap = true, silent = true, desc = "Flash treesitter (or use S)" })
map({ "o" }, "r", require("flash").remote, { desc = "Remote Flash" })
map({ "o", "x" }, "R", require("flash").treesitter_search, { desc = "Treesitter Search" })
map({ "c" }, "<C-s>", require("flash").toggle, { desc = "Toggle Flash Search" })

