local M = {}

M.attach_keymaps = function()
  vim.keymap.set("n", "<leader>no", require("oil").open, { desc = "Oil open current directory" })
end

M.setup = function()
  require("oil").setup()

  M.attach_keymaps()
end

return M
