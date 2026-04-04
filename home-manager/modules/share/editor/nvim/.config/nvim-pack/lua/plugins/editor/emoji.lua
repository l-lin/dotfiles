--
-- A plugin to search for and insert emojis/kaomojis, with auto-completion support, right from Neovim 😀
--

vim.keymap.set("n", "<leader>se", "<cmd>Emoji<cr>", {
  desc = "Emoji",
  noremap = true,
  silent = true,
})
vim.keymap.set("i", "<M-;>", "<cmd>Emoji<cr>", {
  desc = "Emoji",
})
