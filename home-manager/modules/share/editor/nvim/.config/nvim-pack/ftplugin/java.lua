vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop

if vim.fn.executable("java") == 1 and vim.fn.executable("jdtls") == 1 then
  vim.lsp.enable("jdtls")
end
