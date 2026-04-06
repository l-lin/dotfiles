--
--  Faster LuaLS setup for Neovim
--

---@type vim.pack.Spec
return {
  src = "https://github.com/folke/lazydev.nvim",
  data = {
    setup = function()
      require("lazydev").setup({
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          { path = "LazyVim", words = { "LazyVim" } },
          { path = "snacks.nvim", words = { "Snacks" } },
          { path = "lazy.nvim", words = { "LazyVim" } },
        },
      })
    end,
  },
}
