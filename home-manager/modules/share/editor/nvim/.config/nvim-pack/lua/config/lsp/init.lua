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
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = "󰌵 ",
    },
  },
})

vim.lsp.config("*", {
  capabilities = require("config.lsp.common").create_capabilities(),
  on_attach = require("config.lsp.common").on_attach,
})

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
