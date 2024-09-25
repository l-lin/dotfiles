return {
  -- An easy to use HTTP-Rest-Client plugin for neovim written in LUA
  {
    "lima1909/resty.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "folke/which-key.nvim",
        opts = {
          spec = {
            { "<leader>th", group = "http" },
          },
        },
      },
    },
    cmd = { "Resty" },
    keys = {
      {
        "<leader>thr",
        "<cmd>Resty run<cr>",
        mode = { "n", "v" },
        silent = true,
        desc = "Run HTTP request under cursor",
      },
      {
        "<leader>thf",
        "<cmd>Resty favorite<cr>",
        mode = { "n", "v" },
        silent = true,
        desc = "View favorite HTTP request",
      },
    },
  },
}
