vim.bo.tabstop = 2
vim.bo.shiftwidth = vim.o.tabstop

vim.keymap.set("i", "<M-c>", require("functions.lang.markdown").insert_codeblock, { buffer = true, desc = "Add codeblock" })
