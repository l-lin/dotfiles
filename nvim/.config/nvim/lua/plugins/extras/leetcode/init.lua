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
    { "<leader>lc", "<cmd>LcConsole<cr>", silent = true, noremap = true, desc = "LeetCode console" },
    { "<leader>ld", "<cmd>LcDescriptionToggle<cr>", silent = true, noremap = true, desc = "LeetCode toggle description" },
    { "<leader>lh", "<cmd>LcHints<cr>", silent = true, noremap = true, desc = "LeetCode hints" },
    { "<leader>ll", "<cmd>LcLanguage<cr>", silent = true, noremap = true, desc = "LeetCode language" },
    { "<leader>lm", "<cmd>LcMenu<cr>", silent = true, noremap = true, desc = "LeetCode menu" },
    { "<leader>lr", "<cmd>LcRun<cr>", silent = true, noremap = true, desc = "LeetCode run" },
    { "<leader>ls", "<cmd>LcSubmit<cr>", silent = true, noremap = true, desc = "LeetCode submit" },
    { "<leader>lt", "<cmd>LcTabs<cr>", silent = true, noremap = true, desc = "LeetCode tabs" },
  },
  opts = {
    lang = "java",
    sql = "psql",
  },
}
