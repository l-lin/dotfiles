local M = {}

M.attach_keymaps = function()
  vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<CR>", { noremap = true, desc = "Undotree Toggle" })
end

M.setup = function()
  M.attach_keymaps()
end

return M
