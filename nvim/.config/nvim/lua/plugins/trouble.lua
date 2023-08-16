local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  map("n", "<leader>xx", "<cmd>TroubleToggle<cr>", bufopts, "Toggle trouble")
  map("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", bufopts, "Toggle trouble workspace diagnostics")
  map("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", bufopts, "Toggle trouble document diagnostics")
  map("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>", bufopts, "Toggle trouble loclist")
  map("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", bufopts, "Toggle trouble quickfix")
  map("n", "<leader>xu", "<cmd>TroubleToggle lsp_references<cr>", bufopts, "Toggle trouble LSP reference")
end

M.setup = function()
  M.attach_keymaps()
end

return M
