return {
  -- #######################
  -- override default config
  -- #######################

  -- autocompletion engine
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "enter",
        ["<C-e>"] = { "select_and_accept" },
      },
    },
  },

  -- autopairs - not quite as good as nvim-autopairs
  { "echasnovski/mini.pairs", enabled = false },

  -- #######################
  -- add new plugins
  -- #######################

  -- autopairs - better than mini.pairs in my taste
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- split and join arguments
  {
    "echasnovski/mini.splitjoin",
    version = "*",
    event = "LazyFile",
    opts = {
      mappings = {
        toggle = "gS",
      },
    },
  },
}
