-- XML convention is 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop

if vim.fn.executable("lemminx") == 1 then
  vim.lsp.enable("lemminx")
end
