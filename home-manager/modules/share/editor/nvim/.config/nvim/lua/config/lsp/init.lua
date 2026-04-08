local icons = require("config.constants").icons

local diagnostic_levels = {
  { key = "ERROR", highlight = "DiagnosticSignError", icon = icons.diagnostics.error },
  { key = "WARN", highlight = "DiagnosticSignWarn", icon = icons.diagnostics.warn },
  { key = "INFO", highlight = "DiagnosticSignInfo", icon = icons.diagnostics.info },
  { key = "HINT", highlight = "DiagnosticSignHint", icon = icons.diagnostics.hint },
}

---@param counts table<number, integer>
---@param severity table<string, integer>
---@return string
local function format(counts, severity)
  local parts = {}

  for _, diagnostic_level in ipairs(diagnostic_levels) do
    local count = counts[severity[diagnostic_level.key]]
    if count ~= nil and count > 0 then
      table.insert(parts, string.format("%%#%s#%s %d", diagnostic_level.highlight, diagnostic_level.icon, count))
    end
  end

  return table.concat(parts, " ")
end

vim.diagnostic.config({
  float = { border = "rounded", source = true },
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = {
    prefix = "●",
    spacing = 4,
    source = "if_many",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.diagnostics.error,
      [vim.diagnostic.severity.WARN] = icons.diagnostics.warn,
      [vim.diagnostic.severity.INFO] = icons.diagnostics.info,
      [vim.diagnostic.severity.HINT] = icons.diagnostics.hint,
    },
  },
  -- dim whole line
  linehl = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticErrorLine",
    [vim.diagnostic.severity.WARN] = "DiagnosticWarnLine",
    [vim.diagnostic.severity.INFO] = "DiagnosticInfoLine",
    [vim.diagnostic.severity.HINT] = "DiagnosticHintLine",
  },
  status = {
    format = function(counts)
      return format(counts, vim.diagnostic.severity)
    end,
  },
})

vim.lsp.config("*", {
  capabilities = require("config.lsp.common").create_capabilities(),
  on_attach = require("config.lsp.common").on_attach,
})

require("config.lsp.status").setup()

vim.lsp.enable({
  "bashls",
  "eslint",
  "fuzzy_ls",
  "html",
  "jdtls",
  "jsonls",
  "lemminx",
  "lua_ls",
  "nil_ls",
  "rubocop",
  "ruby_lsp",
  "taplo",
  "vtsls",
  "yamlls",
})

vim.keymap.set("n", "<leader>lI", "<cmd>checkhealth vim.lsp<cr>", { desc = "LSP Info" })
vim.keymap.set("n", "<leader>ll", function()
  local lsp_log_path = vim.fn.stdpath("state") .. "/lsp.log"

  vim.cmd("noswapfile tabedit " .. vim.fn.fnameescape(lsp_log_path))
  vim.bo.filetype = "lsp-log"
  vim.bo.readonly = true
  vim.bo.swapfile = false
end, { desc = "LSP logs" })
vim.keymap.set(
  "n",
  "<leader>lc",
  "<cmd>!echo > " .. vim.fn.stdpath("state") .. "/lsp.log<cr>",
  { desc = "Clear LSP logs" }
)
