local function setup()
  require("private-ruby").setup({})
end

---@type vim.pack.Spec[]
return {
  {
    src = "https://github.com/pheen/fuzzy_ruby_server",
  },
  {
    src = "https://codeberg.org/l-lin/private-ruby.nvim",
    data = {
      setup = setup,
    },
  },
}
