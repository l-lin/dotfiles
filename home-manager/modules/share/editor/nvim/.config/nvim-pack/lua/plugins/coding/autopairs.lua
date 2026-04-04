--
-- autopairs for neovim written in lua
--

vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    require("nvim-autopairs").setup({})
  end,
})
