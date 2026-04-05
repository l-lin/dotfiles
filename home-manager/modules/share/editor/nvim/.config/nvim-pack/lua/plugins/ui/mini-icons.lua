--
-- Icon provider.
--

---@type vim.pack.Spec
return {
  src = "https://github.com/nvim-mini/mini.icons",
  data = {
    setup = function()
      require("mini.icons").setup()

      -- Mock nvim-web-devicons to avoid loading it as a dependency,
      -- since it's only used for icons in the statusline and file explorer.
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
}
