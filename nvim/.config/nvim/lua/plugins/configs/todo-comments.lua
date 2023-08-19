local M = {}

M.attach_keymaps = function()
  vim.keymap.set("n", "<M-2>", "<cmd>TodoTelescope<CR>", { noremap = true, desc = "Telescope find TODO (Alt+2)" })
end

M.setup = function()
  require("todo-comments").setup()
  M.attach_keymaps()
end

return M
