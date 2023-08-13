require("nvim-tree").setup {
  view = {
    adaptive_size = true,
  },
}
require("nvim-tree.view").View.winopts.signcolumn = "no"

-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set
map("n", "<A-1>", "<cmd>NvimTreeToggle<CR>", { noremap = true, desc = "Toggle NvimTree" })
map("n", "<A-3>", "<cmd>NvimTreeFindFileToggle<CR>", { noremap = true, desc = "Open NvimTree and target for the current bufname" })
