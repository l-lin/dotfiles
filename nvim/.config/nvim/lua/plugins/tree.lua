local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  map("n", "<A-1>", "<cmd>NvimTreeToggle<CR>", bufopts, "Toggle NvimTree (Alt+1)")
  map("n", "<A-3>", "<cmd>NvimTreeFindFileToggle<CR>", bufopts,
    "Open NvimTree and target for the current bufname (Alt+3)")
end

M.setup = function()
  local config = {
    view = {
      adaptive_size = true,
    },
  }
  require("nvim-tree").setup(config)
  require("nvim-tree.view").View.winopts.signcolumn = "no"

  M.attach_keymaps()
end

return M
