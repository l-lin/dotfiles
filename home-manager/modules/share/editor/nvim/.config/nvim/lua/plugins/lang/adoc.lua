---@type vim.pack.Spec
return
-- A Neovim plugin to preview AsciiDoc documents in the browser.
{
  src = "tigion/nvim-asciidoc-preview",
  data = {
    setup = function()
      require("asciidoc-preview").setup()
    end,
  },
}
