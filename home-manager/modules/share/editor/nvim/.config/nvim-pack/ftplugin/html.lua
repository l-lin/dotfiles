if vim.fn.executable("vscode-html-language-server") == 1 then
  vim.lsp.enable("html")
end
