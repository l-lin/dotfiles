-- Java convention is 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop

require("jdtls").start_or_attach(require("plugins.custom.lang.java").create_config())
