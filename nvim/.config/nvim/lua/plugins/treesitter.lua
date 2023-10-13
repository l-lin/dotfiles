return {
  {
    "nvim-treesitter/nvim-treesitter",
    cmd = { "TSInstallSync" },
  },
  -- Show context of the current function
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "LazyFile",
    opts = {
      multiline_threshold = 5,
    },
  },
}
