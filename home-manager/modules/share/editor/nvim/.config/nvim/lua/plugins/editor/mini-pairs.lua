---@type vim.pack.Spec
return
--
-- Minimal and fast pairs
--
{
  src = "https://github.com/nvim-mini/mini.pairs",
  data = {
    setup = function()
      vim.schedule(function()
        require("mini.pairs").setup()
      end)
    end,
  },
}
