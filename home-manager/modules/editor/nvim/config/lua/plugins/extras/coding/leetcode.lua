return {
  "kawre/leetcode.nvim",
  lazy = false,
  build = ":TSUpdate html",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",

    -- optional
    "rcarriga/nvim-notify",
    "nvim-tree/nvim-web-devicons",

    {
      "folke/which-key.nvim",
      opts = {
        defaults = {
          ["<leader>l"] = { name = "+leet code" },
        },
      },
    },
  },
  keys = {
    { "<leader>lc", "<cmd>Leet console<cr>", silent = true, noremap = true, desc = "LeetCode console" },
    { "<leader>ld", "<cmd>Leet desc<cr>", silent = true, noremap = true, desc = "LeetCode toggle description" },
    { "<leader>lh", "<cmd>Leet hints<cr>", silent = true, noremap = true, desc = "LeetCode hints" },
    { "<leader>li", "<cmd>Leet info<cr>", silent = true, noremap = true, desc = "LeetCode info" },
    { "<leader>ll", "<cmd>Leet lang<cr>", silent = true, noremap = true, desc = "LeetCode language" },
    { "<leader>lm", "<cmd>Leet menu<cr>", silent = true, noremap = true, desc = "LeetCode menu" },
    { "<leader>lr", "<cmd>Leet run<cr>", silent = true, noremap = true, desc = "LeetCode run" },
    { "<leader>ls", "<cmd>Leet submit<cr>", silent = true, noremap = true, desc = "LeetCode submit" },
    { "<leader>lt", "<cmd>Leet tabs<cr>", silent = true, noremap = true, desc = "LeetCode tabs" },
  },
  opts = {
    lang = "java",
    image_support = true,
  },
}
