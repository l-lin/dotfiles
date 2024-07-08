return {
  -- Show context of the current function
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "LazyFile",
    opts = {
      multiline_threshold = 5,
    },
  },
}
