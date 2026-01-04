return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "xml",
    })
  end,
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = { ensure_installed = { "xml" } },
  },
  -- Linters & formatters
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "lemminx", "xmlformatter" } },
  },
}
