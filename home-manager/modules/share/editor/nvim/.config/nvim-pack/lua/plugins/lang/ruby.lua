---@type vim.pack.Spec[]
return {
  --
  -- A Ruby language server for large codebases
  --
  {
    src = "https://github.com/pheen/fuzzy_ruby_server",
  },
  --
  -- Shows private Ruby methods with indicators in Neovim.
  --
  {
    src = "https://codeberg.org/l-lin/private-ruby.nvim",
    data = {
      setup = function()
        require("private-ruby").setup({})
      end,
    },
  },
}
