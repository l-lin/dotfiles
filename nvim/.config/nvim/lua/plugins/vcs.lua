return {
  "tpope/vim-fugitive",
  keys = {
    { "<leader>gs", "<cmd>G<cr>", desc = "git status" },
    { "<leader>gc", "<cmd>G commit<cr>", desc = "git commit" },
    { "<leader>gp", "<cmd>G pull<cr>", desc = "git pull" },
    { "<leader>gP", "<cmd>G push<cr>", desc = "git push" },
    { "<leader>gF", "<cmd>G push --force-with-lease<cr>", desc = "git push --force-with-lease" },
    { "<leader>gb", "<cmd>G blame<cr>", desc = "git blame" },
    { "<leader>gl", "<cmd>0GcLog<cr>", desc = "git log" },
  },
}