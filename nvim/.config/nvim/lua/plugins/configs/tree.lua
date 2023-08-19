local M = {}

M.setup = function()
  require("nvim-tree").setup({
    view = {
      adaptive_size = true,
    },
  })
  require("nvim-tree.view").View.winopts.signcolumn = "no"
end

return M
