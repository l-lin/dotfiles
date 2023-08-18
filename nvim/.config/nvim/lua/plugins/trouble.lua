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

M.config_diagnostics_in_gutter = function(signs)
  vim.fn.sign_define(
    "DiagnosticSignError",
    { texthl = "DiagnosticSignError", text = signs.error, numhl = "DiagnosticSignError" }
  )

  vim.fn.sign_define(
    "DiagnosticSignWarn",
    { texthl = "DiagnosticSignWarn", text = signs.warning, numhl = "DiagnosticSignWarn" }
  )

  vim.fn.sign_define(
    "DiagnosticSignHint",
    { texthl = "DiagnosticSignHint", text = signs.hint, numhl = "DiagnosticSignHint" }
  )

  vim.fn.sign_define(
    "DiagnosticSignInfo",
    { texthl = "DiagnosticSignInfo", text = signs.information, numhl = "DiagnosticSignInfo" }
  )
end

M.setup = function()
  local config = {
    signs = {
      error = "",
      information = "󰋼",
      hint = "󰌵",
      warning = "",
      other = "",
    }
  }
  require("trouble").setup(config)

  M.config_diagnostics_in_gutter(config.signs)
  M.attach_keymaps()
end

return M
