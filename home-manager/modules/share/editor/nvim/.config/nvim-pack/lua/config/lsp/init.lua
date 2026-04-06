local icons = require("config.constants").icons

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

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local value = ev.data.params.value
    vim.api.nvim_echo({ { value.message or "done" } }, false, {
      id = "lsp." .. ev.data.client_id,
      kind = "progress",
      source = "vim.lsp",
      title = value.title,
      status = value.kind ~= "end" and "running" or "success",
      percent = value.percentage,
    })
  end,
})
