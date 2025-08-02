return {
  -- #######################
  -- override default config
  -- #######################

  -- Use hlchunk instead to render the indent lines.
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        scope = {
          hl = "NormalFloat"
        }
      },
    },
  },
}
