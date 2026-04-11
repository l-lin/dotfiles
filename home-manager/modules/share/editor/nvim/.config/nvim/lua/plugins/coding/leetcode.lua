---@type vim.pack.Spec[]
return {
  { src = "nvim-lua/plenary.nvim" },
  { src = "MunifTanjim/nui.nvim" },
  { src = "rcarriga/nvim-notify" },
  { src = "nvim-tree/nvim-web-devicons" },
  -- A Neovim plugin enabling you to solve LeetCode problems.
  {
    src = "kawre/leetcode.nvim",
    data = {
      setup = function()
        require("leetcode").setup({ lang = "java", image_support = true })
        -- stylua: ignore start
        vim.keymap.set("n", "<leader>Lc", "<cmd>Leet console<cr>", { silent = true, noremap = true, desc = "LeetCode console" })
        vim.keymap.set("n", "<leader>Ld", "<cmd>Leet desc<cr>", { silent = true, noremap = true, desc = "LeetCode toggle description" })
        vim.keymap.set("n", "<leader>Lh", "<cmd>Leet hints<cr>", { silent = true, noremap = true, desc = "LeetCode hints" })
        vim.keymap.set("n", "<leader>Li", "<cmd>Leet info<cr>", { silent = true, noremap = true, desc = "LeetCode info" })
        vim.keymap.set("n", "<leader>Ll", "<cmd>Leet lang<cr>", { silent = true, noremap = true, desc = "LeetCode language" })
        vim.keymap.set("n", "<leader>Lm", "<cmd>Leet menu<cr>", { silent = true, noremap = true, desc = "LeetCode menu" })
        vim.keymap.set("n", "<leader>Lr", "<cmd>Leet run<cr>", { silent = true, noremap = true, desc = "LeetCode run" })
        vim.keymap.set("n", "<leader>Ls", "<cmd>Leet submit<cr>", { silent = true, noremap = true, desc = "LeetCode submit" })
        vim.keymap.set("n", "<leader>Lt", "<cmd>Leet tabs<cr>", { silent = true, noremap = true, desc = "LeetCode tabs" })
        -- stylua: ignore end
      end,
    },
  },
}
