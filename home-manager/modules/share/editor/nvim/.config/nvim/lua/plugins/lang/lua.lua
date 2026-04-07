---@type vim.pack.Spec
return
--  Faster LuaLS setup for Neovim
{
  src = "https://github.com/folke/lazydev.nvim",
  data = {
    setup = function()
      vim.schedule(function()
        require("lazydev").setup({
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            { path = "LazyVim", words = { "LazyVim" } },
            { path = "snacks.nvim", words = { "Snacks" } },
            { path = "lazy.nvim", words = { "LazyVim" } },
          },
        })
      end)
    end,
  },
}
