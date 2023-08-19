local M = {}

local function config_diagnostics_in_gutter(signs)
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

  config_diagnostics_in_gutter(config.signs)
end

return M
