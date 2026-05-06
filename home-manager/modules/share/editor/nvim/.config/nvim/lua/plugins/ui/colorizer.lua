---@type vim.pack.Spec
return
-- The fastest Neovim colorizer
{
  src = "https://github.com/catgoose/nvim-colorizer.lua",
  data = {
    setup = function()
      vim.schedule(require("colorizer").setup)
    end,
  },
}
