vim.diagnostic.config({
  float = { border = "rounded" },
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = {
    prefix = "●",
    spacing = 4,
    source = "if_many",
  },
})

vim.lsp.config("*", {
  capabilities = require("config.lsp.common").create_capabilities(),
  on_attach = require("config.lsp.common").on_attach,
})
