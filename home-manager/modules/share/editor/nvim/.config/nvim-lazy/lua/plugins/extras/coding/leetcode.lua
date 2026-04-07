return {
  {
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
    },
    keys = {
      { "<leader>L", "", desc = "+leetcode", mode = {"n", "v"} },
      { "<leader>Lc", "<cmd>Leet console<cr>", silent = true, noremap = true, desc = "LeetCode console" },
      { "<leader>Ld", "<cmd>Leet desc<cr>", silent = true, noremap = true, desc = "LeetCode toggle description" },
      { "<leader>Lh", "<cmd>Leet hints<cr>", silent = true, noremap = true, desc = "LeetCode hints" },
      { "<leader>Li", "<cmd>Leet info<cr>", silent = true, noremap = true, desc = "LeetCode info" },
      { "<leader>Ll", "<cmd>Leet lang<cr>", silent = true, noremap = true, desc = "LeetCode language" },
      { "<leader>Lm", "<cmd>Leet menu<cr>", silent = true, noremap = true, desc = "LeetCode menu" },
      { "<leader>Lr", "<cmd>Leet run<cr>", silent = true, noremap = true, desc = "LeetCode run" },
      { "<leader>Ls", "<cmd>Leet submit<cr>", silent = true, noremap = true, desc = "LeetCode submit" },
      { "<leader>Lt", "<cmd>Leet tabs<cr>", silent = true, noremap = true, desc = "LeetCode tabs" },
    },
    opts = {
      lang = "java",
      image_support = true,
    },
  },
}
