---@type vim.pack.Spec[]
return {
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  -- A Neovim plugin enabling you to solve LeetCode problems.
  {
    src = "https://github.com/kawre/leetcode.nvim",
    data = {
      setup = function()
        require("leetcode").setup({ lang = "golang", image_support = true, plugins = { non_standalone = true } })
        -- stylua: ignore start
        require("which-key").add({ mode = "n", { "<leader>L", group = "Leetcode" } })

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
