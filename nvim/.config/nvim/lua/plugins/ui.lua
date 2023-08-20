return {
  -- navigate between neovim and multiplexers
  {
    "numToStr/Navigator.nvim",
    keys = {
      { "<C-h>", "<cmd>NavigatorLeft<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate left" },
      { "<C-l>", "<cmd>NavigatorRight<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate right" },
      { "<C-k>", "<cmd>NavigatorUp<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate up" },
      { "<C-j>", "<cmd>NavigatorDown<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate down" },
    },
    cmd = { "NavigatorUp", "NavigatorDown", "NavigatorRight", "NavigatorLeft" },
    config = function()
      require("Navigator").setup({})
    end,
  },

  -- dashboard
  {
    "goolord/alpha-nvim",
    opts = {
      section = {
        header = {
          val = "",
        },
      },
    },
  },
}
