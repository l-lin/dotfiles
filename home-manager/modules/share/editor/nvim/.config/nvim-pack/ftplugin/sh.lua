if vim.fn.executable("bash-language-server") == 1 then
  vim.lsp.enable("bashls")
end
