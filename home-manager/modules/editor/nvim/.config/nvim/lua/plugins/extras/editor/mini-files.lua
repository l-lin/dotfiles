return {
  -- #######################
  -- override default config
  -- #######################

  {
    "echasnovski/mini.files",
    keys = {
      { "<A-1>", "<leader>fm", desc = "Open mini.files (directory of current file) (Alt+1)", remap = true },
    },
    opts = {
      windows = {
        preview = true,
        width_focus = 50,
        width_preview = 100,
      },
      options = {
        -- Whether to use for editing directories.
        use_as_default_explorer = true,
      },
    },
  },
}
