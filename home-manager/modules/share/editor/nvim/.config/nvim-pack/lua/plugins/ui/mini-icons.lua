--
-- Icon provider.
--

---@type vim.pack.Spec
return {
  src = "https://github.com/nvim-mini/mini.icons",
  data = {
    setup = function()
      require("mini.icons").setup()
    end,
  }
}
