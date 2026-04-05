vim.o.tabstop = 2
vim.o.shiftwidth = vim.o.tabstop

if vim.fn.executable("vscode-json-language-server") == 1 then
  vim.lsp.enable("jsonls")
end
