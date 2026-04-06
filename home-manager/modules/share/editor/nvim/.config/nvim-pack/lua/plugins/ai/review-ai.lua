---@type vim.pack.Spec
return {
  src = "https://codeberg.org/l-lin/review-ai.nvim",
  data = {
    setup = function()
      require("review-ai").setup()
      vim.keymap.set("n", "<leader>ar", "<cmd>ReviewAi<cr>", { desc = "Review AI changes" })
    end,
  },
}
