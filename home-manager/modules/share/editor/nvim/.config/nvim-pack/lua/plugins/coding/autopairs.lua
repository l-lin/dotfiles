---@type vim.pack.Spec
return
-- autopairs for neovim written in lua
{
  src = "https://github.com/windwp/nvim-autopairs",
  data = {
    setup = function()
      vim.api.nvim_create_autocmd("InsertEnter", {
        once = true,
        callback = function()
          require("nvim-autopairs").setup({})
        end,
      })
    end,
  },
}
