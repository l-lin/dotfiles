if vim.fn.executable("vscode-eslint-language-server") == 1 then
  vim.lsp.enable("eslint")
end

if vim.fn.executable("vtsls") == 1 then
  vim.lsp.enable("vtsls")
end
