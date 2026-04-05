if vim.fn.executable("yaml-language-server") == 1 then
  vim.lsp.enable("yamlls")
end
