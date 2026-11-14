vim.bo.tabstop = 2
vim.bo.shiftwidth = vim.o.tabstop

if not vim.bo.readonly and vim.bo.modifiable then
  vim.keymap.set({ "n", "i" }, "<M-l>", require("functions.lang.markdown").convert_or_toggle_task, { desc = "Convert bullet to task or toggle task", noremap = true, buffer = true })
  vim.keymap.set({ "i", "v" }, "<Tab>", require("functions.lang.markdown").smart_indent, { desc = "Indent bullet point", noremap = true, buffer = true })
  vim.keymap.set({ "i", "v" }, "<S-Tab>", require("functions.lang.markdown").smart_dedent, { desc = "Dedent bullet point", noremap = true, buffer = true })
end
